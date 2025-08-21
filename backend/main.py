from fastapi import FastAPI, HTTPException, Depends, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
import pyodbc
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, auth

app = FastAPI()

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



# Database connection
def get_db_connection():
    try:
        conn = pyodbc.connect(
            "DRIVER={ODBC Driver 17 for SQL Server};"
            "SERVER=DESKTOP-8BL3MIG\\SQLEXPRESS;"
            "DATABASE=task_tracker;"
            "Trusted_Connection=yes;"
        )
        return conn
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")

# Security
security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        token = credentials.credentials
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

# Pydantic models
class UserCreate(BaseModel):
    email: str
    name: str
    role: str

class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None
    assigned_to: int
    deadline: Optional[datetime] = None

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None
    assigned_to: Optional[int] = None  # Added this field
    deadline: Optional[datetime] = None

class TaskSubmission(BaseModel):
    description: str
    attachment_url: Optional[str] = None

class ProgressReportCreate(BaseModel):
    internee_id: int
    period_start: str
    period_end: str
    tasks_completed: int
    tasks_pending: int
    overall_performance: str
    comments: Optional[str] = None

# Routes
@app.post("/register/")
async def register_user(user: UserCreate, current_user: dict = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Check if user already exists
        cursor.execute("SELECT id FROM users WHERE firebase_id = ?", current_user['uid'])
        existing_user = cursor.fetchone()
        
        if existing_user:
            return {
                "message": "User already registered", 
                "user_id": existing_user[0],
                "status": "existing"
            }
        
        # Register new user
        cursor.execute(
            "INSERT INTO users (firebase_id, email, name, role) VALUES (?, ?, ?, ?)",
            current_user['uid'], user.email, user.name, user.role
        )
        conn.commit()
        
        # Get the inserted user ID
        cursor.execute("SELECT id FROM users WHERE firebase_id = ?", current_user['uid'])
        user_id = cursor.fetchone()[0]
        
        return {
            "message": "User registered successfully",
            "user_id": user_id,
            "status": "created"
        }
        
    except pyodbc.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=f"Database error: {str(e)}")
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

@app.get("/users/me/")
async def read_current_user(current_user: dict = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute(
            "SELECT id, email, name, role FROM users WHERE firebase_id = ?", 
            current_user['uid']
        )
        user = cursor.fetchone()
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found in database")
        
        return {
            "id": user[0],
            "email": user[1],
            "name": user[2],
            "role": user[3],
            "firebase_id": current_user['uid']
        }
    except pyodbc.Error as e:
        raise HTTPException(status_code=400, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

@app.get("/users/internees/")
async def get_all_internees(current_user: dict = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Verify user is admin
        cursor.execute(
            "SELECT role FROM users WHERE firebase_id = ?", 
            current_user['uid']
        )
        user_role = cursor.fetchone()
        
        if not user_role or user_role[0] != 'admin':
            raise HTTPException(status_code=403, detail="Only admins can access this resource")
        
        # Get all internees
        cursor.execute(
            "SELECT id, email, name FROM users WHERE role = 'internee'"
        )
        internees = []
        for row in cursor.fetchall():
            internees.append({
                "id": row[0],
                "email": row[1],
                "name": row[2]
            })
        
        return internees
    except pyodbc.Error as e:
        raise HTTPException(status_code=400, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

@app.post("/tasks/")
async def create_task(task: TaskCreate, current_user: dict = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get current user ID
        cursor.execute(
            "SELECT id, role FROM users WHERE firebase_id = ?", 
            current_user['uid']
        )
        user = cursor.fetchone()
        
        if not user or user[1] != 'admin':
            raise HTTPException(status_code=403, detail="Only admins can create tasks")
        
        # Create task
        cursor.execute(
            """INSERT INTO tasks 
            (title, description, created_by, assigned_to, deadline) 
            VALUES (?, ?, ?, ?, ?)""",
            task.title, task.description, user[0], task.assigned_to, task.deadline
        )
        conn.commit()
        
        return {"message": "Task created successfully"}
    except pyodbc.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=f"Database error: {str(e)}")
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

@app.get("/tasks/")
async def get_tasks(current_user: dict = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get current user ID and role
        cursor.execute(
            "SELECT id, role FROM users WHERE firebase_id = ?", 
            current_user['uid']
        )
        user = cursor.fetchone()
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        tasks = []
        if user[1] == 'admin':
            # Admin can see all tasks
            cursor.execute("""
                SELECT t.id, t.title, t.description, t.status, t.deadline, 
                       u1.name as created_by, u2.name as assigned_to, t.assigned_to as assigned_to_id
                FROM tasks t
                JOIN users u1 ON t.created_by = u1.id
                JOIN users u2 ON t.assigned_to = u2.id
                ORDER BY t.created_at DESC
            """)
        else:
            # Internee can only see their own tasks
            cursor.execute("""
                SELECT t.id, t.title, t.description, t.status, t.deadline, 
                       u1.name as created_by, u2.name as assigned_to, t.assigned_to as assigned_to_id
                FROM tasks t
                JOIN users u1 ON t.created_by = u1.id
                JOIN users u2 ON t.assigned_to = u2.id
                WHERE t.assigned_to = ?
                ORDER BY t.created_at DESC
            """, user[0])
        
        for row in cursor.fetchall():
            tasks.append({
                "id": row[0],
                "title": row[1],
                "description": row[2],
                "status": row[3],
                "deadline": row[4],
                "created_by": row[5],
                "assigned_to": row[6],
                "assigned_to_id": row[7]
            })
        
        return tasks
    except pyodbc.Error as e:
        raise HTTPException(status_code=400, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

@app.put("/tasks/{task_id}/")
async def update_task(task_id: int, task: TaskUpdate, current_user: dict = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get current user ID and role
        cursor.execute(
            "SELECT id, role FROM users WHERE firebase_id = ?", 
            current_user['uid']
        )
        user = cursor.fetchone()
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Build update query based on provided fields
        update_fields = []
        params = []
        
        if task.title is not None:
            update_fields.append("title = ?")
            params.append(task.title)
        if task.description is not None:
            update_fields.append("description = ?")
            params.append(task.description)
        if task.status is not None:
            update_fields.append("status = ?")
            params.append(task.status)
        if task.assigned_to is not None:
            update_fields.append("assigned_to = ?")
            params.append(task.assigned_to)
        if task.deadline is not None:
            update_fields.append("deadline = ?")
            params.append(task.deadline)
            
        if not update_fields:
            return {"message": "No fields to update"}
            
        # Add updated_at and task_id to params
        update_fields.append("updated_at = ?")
        params.append(datetime.now())
        params.append(task_id)
        
        # Verify user has permission to update this task
        if user[1] == 'internee':
            # Internees can only update status
            allowed_fields = ["status = ?", "updated_at = ?"]
            if not all(field in allowed_fields for field in update_fields[:-1]):
                raise HTTPException(status_code=403, detail="Internees can only update task status")
            
            # Verify task is assigned to this internee
            cursor.execute(
                "SELECT assigned_to FROM tasks WHERE id = ?",
                task_id
            )
            task_assigned_to = cursor.fetchone()
            
            if not task_assigned_to or task_assigned_to[0] != user[0]:
                raise HTTPException(status_code=403, detail="Not authorized to update this task")
        
        # Execute update
        update_query = f"UPDATE tasks SET {', '.join(update_fields)} WHERE id = ?"
        cursor.execute(update_query, params)
        
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Task not found")
            
        conn.commit()
        
        return {"message": "Task updated successfully"}
    except pyodbc.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=f"Database error: {str(e)}")
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

@app.delete("/tasks/{task_id}/")
async def delete_task(task_id: int, current_user: dict = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get current user role
        cursor.execute(
            "SELECT role FROM users WHERE firebase_id = ?", 
            current_user['uid']
        )
        user_role = cursor.fetchone()
        
        if not user_role or user_role[0] != 'admin':
            raise HTTPException(status_code=403, detail="Only admins can delete tasks")
        
        # Delete task
        cursor.execute("DELETE FROM tasks WHERE id = ?", task_id)
        
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Task not found")
            
        conn.commit()
        
        return {"message": "Task deleted successfully"}
    except pyodbc.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=f"Database error: {str(e)}")
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

@app.post("/tasks/{task_id}/submit/")
async def submit_task(task_id: int, submission: TaskSubmission, current_user: dict = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get current user ID
        cursor.execute(
            "SELECT id, role FROM users WHERE firebase_id = ?", 
            current_user['uid']
        )
        user = cursor.fetchone()
        
        if not user or user[1] != 'internee':
            raise HTTPException(status_code=403, detail="Only internees can submit tasks")
        
        # Verify task is assigned to this internee
        cursor.execute(
            "SELECT assigned_to FROM tasks WHERE id = ?",
            task_id
        )
        task_assigned_to = cursor.fetchone()
        
        if not task_assigned_to:
            raise HTTPException(status_code=404, detail="Task not found")
            
        if task_assigned_to[0] != user[0]:
            raise HTTPException(status_code=403, detail="Not authorized to submit for this task")
        
        # Create submission
        cursor.execute(
            """INSERT INTO task_submissions 
            (task_id, submitted_by, description, attachment_url) 
            VALUES (?, ?, ?, ?)""",
            task_id, user[0], submission.description, submission.attachment_url
        )
        
        # Update task status to completed
        cursor.execute(
            "UPDATE tasks SET status = 'completed', updated_at = ? WHERE id = ?",
            datetime.now(), task_id
        )
        
        conn.commit()
        
        return {"message": "Task submitted successfully"}
    except pyodbc.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=f"Database error: {str(e)}")
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

@app.get("/tasks/{task_id}/submissions/")
async def get_task_submissions(task_id: int, current_user: dict = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get current user ID and role
        cursor.execute(
            "SELECT id, role FROM users WHERE firebase_id = ?", 
            current_user['uid']
        )
        user = cursor.fetchone()
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Verify user has permission to view submissions
        if user[1] == 'internee':
            # Internee can only see their own submissions
            cursor.execute("""
                SELECT ts.id, ts.description, ts.attachment_url, ts.submitted_at, u.name
                FROM task_submissions ts
                JOIN users u ON ts.submitted_by = u.id
                WHERE ts.task_id = ? AND ts.submitted_by = ?
                ORDER BY ts.submitted_at DESC
            """, task_id, user[0])
        else:
            # Admin can see all submissions for the task
            cursor.execute("""
                SELECT ts.id, ts.description, ts.attachment_url, ts.submitted_at, u.name
                FROM task_submissions ts
                JOIN users u ON ts.submitted_by = u.id
                WHERE ts.task_id = ?
                ORDER BY ts.submitted_at DESC
            """, task_id)
        
        submissions = []
        for row in cursor.fetchall():
            submissions.append({
                "id": row[0],
                "description": row[1],
                "attachment_url": row[2],
                "submitted_at": row[3],
                "submitted_by": row[4]
            })
        
        return submissions
    except pyodbc.Error as e:
        raise HTTPException(status_code=400, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

@app.post("/reports/")
async def create_progress_report(report: ProgressReportCreate, current_user: dict = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get current user role
        cursor.execute(
            "SELECT id, role FROM users WHERE firebase_id = ?", 
            current_user['uid']
        )
        user = cursor.fetchone()
        
        if not user or user[1] != 'admin':
            raise HTTPException(status_code=403, detail="Only admins can create reports")
        
        # Create report
        cursor.execute(
            """INSERT INTO progress_reports 
            (internee_id, generated_by, period_start, period_end, 
             tasks_completed, tasks_pending, overall_performance, comments) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            report.internee_id, user[0], report.period_start, report.period_end,
            report.tasks_completed, report.tasks_pending, report.overall_performance, report.comments
        )
        conn.commit()
        
        return {"message": "Progress report created successfully"}
    except pyodbc.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=f"Database error: {str(e)}")
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

@app.get("/reports/")
async def get_progress_reports(current_user: dict = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get current user ID and role
        cursor.execute(
            "SELECT id, role FROM users WHERE firebase_id = ?", 
            current_user['uid']
        )
        user = cursor.fetchone()
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        reports = []
        if user[1] == 'admin':
            # Admin can see all reports
            cursor.execute("""
                SELECT pr.id, u1.name as internee_name, u2.name as generated_by, 
                       pr.period_start, pr.period_end, pr.tasks_completed, 
                       pr.tasks_pending, pr.overall_performance, pr.comments, pr.created_at
                FROM progress_reports pr
                JOIN users u1 ON pr.internee_id = u1.id
                JOIN users u2 ON pr.generated_by = u2.id
                ORDER BY pr.created_at DESC
            """)
        else:
            # Internee can only see their own reports
            cursor.execute("""
                SELECT pr.id, u1.name as internee_name, u2.name as generated_by, 
                       pr.period_start, pr.period_end, pr.tasks_completed, 
                       pr.tasks_pending, pr.overall_performance, pr.comments, pr.created_at
                FROM progress_reports pr
                JOIN users u1 ON pr.internee_id = u1.id
                JOIN users u2 ON pr.generated_by = u2.id
                WHERE pr.internee_id = ?
                ORDER BY pr.created_at DESC
            """, user[0])
        
        for row in cursor.fetchall():
            reports.append({
                "id": row[0],
                "internee_name": row[1],
                "generated_by": row[2],
                "period_start": row[3],
                "period_end": row[4],
                "tasks_completed": row[5],
                "tasks_pending": row[6],
                "overall_performance": row[7],
                "comments": row[8],
                "created_at": row[9]
            })
        
        return reports
    except pyodbc.Error as e:
        raise HTTPException(status_code=400, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
    finally:
        conn.close()

# Health check endpoint
@app.get("/health/")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now()}

# Test database connection endpoint
@app.get("/test-db/")
async def test_database():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        conn.close()
        return {"status": "Database connection successful", "result": result[0]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")