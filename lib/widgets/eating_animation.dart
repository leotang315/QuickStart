import 'package:flutter/material.dart';

class EatingAnimation extends StatefulWidget {
  final String childImagePath; // 小孩照片路径
  final Widget targetIcon;     // 要"吃"的桌面图标
  
  const EatingAnimation({
    Key? key,
    required this.childImagePath,
    required this.targetIcon,
  }) : super(key: key);

  @override
  _EatingAnimationState createState() => _EatingAnimationState();
}

class _EatingAnimationState extends State<EatingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mouthController;
  late AnimationController _iconController;
  late AnimationController _chewController;
  
  late Animation<double> _mouthAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<Offset> _iconPositionAnimation;
  late Animation<double> _chewAnimation;

  @override
  void initState() {
    super.initState();
    
    // 嘴巴张合动画
    _mouthController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    // 图标移动和缩放动画
    _iconController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // 咀嚼动画
    _chewController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _setupAnimations();
    _startEatingSequence();
  }
  
  void _setupAnimations() {
    // 嘴巴张合（可以通过调整图片透明度或使用多张图片实现）
    _mouthAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mouthController,
      curve: Curves.easeInOut,
    ));
    
    // 图标缩放（被吃掉时逐渐变小）
    _iconScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Interval(0.6, 1.0, curve: Curves.easeIn),
    ));
    
    // 图标位置（移动到嘴巴位置）
    _iconPositionAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(-0.3, -0.2), // 调整到嘴巴位置
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));
    
    // 咀嚼动画
    _chewAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_chewController);
  }
  
  void _startEatingSequence() async {
    // 1. 张嘴
    await _mouthController.forward();
    
    // 2. 图标移动到嘴巴
    await _iconController.forward();
    
    // 3. 咀嚼动画（重复几次）
    for (int i = 0; i < 3; i++) {
      await _chewController.forward();
      await _chewController.reverse();
    }
    
    // 4. 闭嘴
    await _mouthController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 小孩照片
        Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_mouthAnimation, _chewAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_chewAnimation.value * 0.05), // 咀嚼时轻微缩放
                child: Image.asset(
                  widget.childImagePath,
                  width: 200,
                  height: 200,
                ),
              );
            },
          ),
        ),
        
        // 被吃的图标
        Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_iconPositionAnimation, _iconScaleAnimation]),
            builder: (context, child) {
              return Transform.translate(
                offset: _iconPositionAnimation.value * 100,
                child: Transform.scale(
                  scale: _iconScaleAnimation.value,
                  child: widget.targetIcon,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mouthController.dispose();
    _iconController.dispose();
    _chewController.dispose();
    super.dispose();
  }
}