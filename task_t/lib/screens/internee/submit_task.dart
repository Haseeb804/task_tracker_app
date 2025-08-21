import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_t/services/api_service.dart';

class SubmitTaskScreen extends StatefulWidget {
  final String taskId;

  const SubmitTaskScreen({super.key, required this.taskId});

  @override
  State<SubmitTaskScreen> createState() => _SubmitTaskScreenState();
}

class _SubmitTaskScreenState extends State<SubmitTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  File? _selectedFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Select Image Source',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? image = await picker.pickImage(source: ImageSource.camera);
                        if (image != null) {
                          setState(() {
                            _selectedFile = File(image.path);
                          });
                        }
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            _selectedFile = File(image.path);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.deepOrange,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final success = await ApiService.submitTaskWithFile(
        widget.taskId,
        _notesController.text,
        _selectedFile,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task submitted successfully'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Submit Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.upload_file,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Submit Your Work',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add notes and attach files to complete your submission',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // Notes Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submission Notes',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 5,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Describe your work, challenges faced, and any additional comments...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(top: 12, left: 12),
                          child: Icon(Icons.notes, color: Colors.deepOrange),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.deepOrange, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please add some notes about your submission';
                        }
                        if (value!.length < 10) {
                          return 'Please provide more detailed notes (at least 10 characters)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // File Upload Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade800,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _selectedFile == null ? Icons.attach_file : Icons.image,
                            color: Colors.deepOrange,
                          ),
                        ),
                        title: Text(
                          _selectedFile == null
                              ? 'No file selected'
                              : _selectedFile!.path.split('/').last,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _selectedFile == null
                              ? 'Tap to add screenshots or documents'
                              : 'Tap to change file',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.upload,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onTap: _pickFile,
                      ),
                      if (_selectedFile != null)
                        Container(
                          margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'File ready for submission',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedFile = null;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                child: Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Optional: Attach screenshots, documents, or any relevant files',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      disabledBackgroundColor: Colors.deepOrange.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.deepOrange.withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Submit Task',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}