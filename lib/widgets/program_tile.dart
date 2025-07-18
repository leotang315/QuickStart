import 'package:flutter/material.dart';

import '../models/program.dart';
import '../services/icon_service.dart';
import '../services/launcher_service.dart';

class ProgramTile extends StatefulWidget {
  final Program program;
  final LauncherService launcherService;

  const ProgramTile({
    Key? key,
    required this.program,
    required this.launcherService,
  }) : super(key: key);

  @override
  _ProgramTileState createState() => _ProgramTileState();
}

class _ProgramTileState extends State<ProgramTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: () async {
            await widget.launcherService.launchProgram(widget.program);
          },
          onHover: (hover) {
            setState(() {
              _isHovering = hover;
            });
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _isHovering
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.7)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child:
                        IconService.getFileIcon(
                          widget.program.path,
                          size: IconSize.jumbo,
                        ) ??
                        Icon(
                          Icons.insert_drive_file,
                          color: Colors.white,
                          size: 24,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    widget.program.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(fontSize: 12, color: Color(0xFF495057)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
