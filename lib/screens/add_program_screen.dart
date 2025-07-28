import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/program.dart';
import '../services/database_service.dart';

class AddProgramScreen extends StatefulWidget {
  final Program? program;

  const AddProgramScreen({super.key, this.program});

  @override
  State<AddProgramScreen> createState() => _AddProgramScreenState();
}

class _AddProgramScreenState extends State<AddProgramScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pathController = TextEditingController();
  final _argumentsController = TextEditingController();
  final _categoryController = TextEditingController();
  final _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    if (widget.program != null) {
      _nameController.text = widget.program!.name;
      _pathController.text = widget.program!.path;
      _argumentsController.text = widget.program!.arguments ?? '';
      _categoryController.text = widget.program!.category ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    _argumentsController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe', 'bat', 'cmd', 'lnk'],
    );

    if (result != null) {
      setState(() {
        _pathController.text = result.files.single.path!;
        if (_nameController.text.isEmpty) {
          _nameController.text = result.files.single.name.split('.').first;
        }
      });
    }
  }

  Future<void> _saveProgram() async {
    if (_formKey.currentState!.validate()) {
      final program = Program(
        id: widget.program?.id,
        name: _nameController.text,
        path: _pathController.text,
        arguments:
            _argumentsController.text.isEmpty
                ? null
                : _argumentsController.text,
        category:
            _categoryController.text.isEmpty ? null : _categoryController.text,
      );

      if (widget.program == null) {
        await _databaseService.insertProgram(program);
      } else {
        await _databaseService.updateProgram(program);
      }

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.program == null ? '添加程序' : '编辑程序')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '程序名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入程序名称';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pathController,
                      decoration: InputDecoration(
                        labelText: '程序路径',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入程序路径';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(onPressed: _pickFile, child: Text('浏览')),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _argumentsController,
                decoration: InputDecoration(
                  labelText: '启动参数（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: '分类（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _saveProgram,
                  child: Text('保存'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
