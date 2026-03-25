import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void _onThemeChanged(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        isDarkMode: isDarkMode,
        onThemeChanged: _onThemeChanged,
      ),
      routes: {
        '/profile': (context) => ProfileCard(
          isDarkMode: isDarkMode,
          onThemeChanged: _onThemeChanged,
        ),
      },
    );
  }
}

class ProfileCard extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const ProfileCard({required this.isDarkMode, required this.onThemeChanged});

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _avatarTapController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _avatarScaleAnimation;
  late Animation<double> _avatarTapScaleAnimation;
  bool _isAvatarExpanded = false;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  // Particle system
  final List<Particle> _particles = [];
  final Random _random = Random();

  // Stats animation
  late AnimationController _statsController;
  final Map<String, int> _stats = {
    'Projects': 0,
    'Followers': 0,
    'Students': 0,
  };
  final Map<String, int> _targetStats = {
    'Projects': 47,
    'Followers': 2800,
    'Students': 1500,
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _avatarTapController = AnimationController(
      duration: Duration(milliseconds: 240),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _particleController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _statsController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 0.45).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _avatarScaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _avatarTapScaleAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _avatarTapController, curve: Curves.easeOutBack),
    );

    // Initialize particles
    for (int i = 0; i < 30; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.5 + 0.2,
        opacity: _random.nextDouble() * 0.5 + 0.3,
      ));
    }

    // Listen to scroll for parallax
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    _controller.forward();
    _animateStats();
  }

  void _animateStats() async {
    await Future.delayed(Duration(milliseconds: 500));
    _statsController.forward();
    _statsController.addListener(() {
      setState(() {
        _stats['Projects'] = (_targetStats['Projects']! * _statsController.value).round();
        _stats['Followers'] = (_targetStats['Followers']! * _statsController.value).round();
        _stats['Students'] = (_targetStats['Students']! * _statsController.value).round();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _avatarTapController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _statsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleAvatarScale() {
    setState(() {
      _isAvatarExpanded = !_isAvatarExpanded;
      if (_isAvatarExpanded) {
        _avatarTapController.forward();
      } else {
        _avatarTapController.reverse();
      }
    });
  }

  Future<void> _shareVCard() async {
    final String vcard = '''BEGIN:VCARD
VERSION:3.0
FN:Femi Adeleke
N:Adeleke;Femi;;;
TITLE:Mobile App Dev Guru
EMAIL;TYPE=WORK:femi@tapr.example
TEL;TYPE=CELL:+1234567890
ORG:tapr
END:VCARD''';

    try {
      await Share.share(vcard, subject: 'My contact card');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.grey[800] : Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile'),
      ),
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)]
                    : [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
              ),
            ),
          ),
          // Floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                  isDark: isDark,
                ),
                size: Size.infinite,
              );
            },
          ),
          // Background image with parallax
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, _scrollOffset * 0.3),
              child: Image.asset(
                'assets/image1.jpg',
                fit: BoxFit.cover,
                opacity: AlwaysStoppedAnimation(0.4),
              ),
            ),
          ),
          // Dark overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _opacityAnimation,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withOpacity(_opacityAnimation.value),
                );
              },
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar with theme toggle
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAnimatedLogo(),
                      Row(
                        children: [
                          _buildAnimatedIconButton(
                            icon: isDark ? Icons.light_mode : Icons.dark_mode,
                            onTap: () => widget.onThemeChanged(!isDark),
                          ),
                          SizedBox(width: 8),
                          _buildShimmerButton(),
                        ],
                      ),
                    ],
                  ),
                ),
                // Push content to bottom
                Spacer(),
                // Profile picture + name
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pulsing avatar with glow
                      _buildPulsingAvatar(),
                      SizedBox(height: 16),
                      // Animated name with typewriter effect
                      _buildAnimatedName(),
                      SizedBox(height: 6),
                      // Social media links
                      _buildSocialLinks(),
                    ],
                  ),
                ),
                SizedBox(height: 18),
                // White/Dark bottom section
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black54 : Colors.black26,
                            blurRadius: 18,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Animated stats
                            _buildAnimatedStats(),
                            SizedBox(height: 22),
                            // Two buttons
                            _buildActionButtons(),
                            SizedBox(height: 22),
                            // About
                            _buildSectionTitle('ABOUT', textColor),
                            SizedBox(height: 8),
                            _buildAboutText(isDark),
                            SizedBox(height: 16),
                            // Expertise with animated progress bars
                            _buildSectionTitle('EXPERTISE', textColor),
                            SizedBox(height: 8),
                            _buildSkillBars(isDark),
                            SizedBox(height: 24),
                            // Signature wave animation
                            _buildSignatureWave(isDark),
                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Text(
            'tapr',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.purple.withOpacity(0.5),
                  blurRadius: 10 * value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedIconButton({required IconData icon, required VoidCallback onTap}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: (1 - value) * pi,
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
          ),
        );
      },
    );
  }

  Widget _buildShimmerButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + value * 2, 0),
              end: Alignment(-0.5 + value * 2, 0),
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.6),
                Colors.white.withOpacity(0.3),
              ],
            ),
          ),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white, width: 1.5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🚀 Get your own profile card!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.deepPurple,
                ),
              );
            },
            child: Text('Get your card'),
          ),
        );
      },
    );
  }

  Widget _buildPulsingAvatar() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _toggleAvatarScale();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 120 + (_pulseController.value * 15),
                height: 120 + (_pulseController.value * 15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.purple.withOpacity(0.4 - _pulseController.value * 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Avatar
              ScaleTransition(
                scale: _avatarScaleAnimation,
                child: ScaleTransition(
                  scale: _avatarTapScaleAnimation,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.pink, Colors.orange],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/profile.png'),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedName() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1200),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1 - value) * 30, 0),
            child: Text(
              'Femi Adeleke',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialLinks() {
    return Row(
      children: [
        _buildSocialButton(Icons.link, () => _openUrl('https://linkedin.com')),
        SizedBox(width: 12),
        _buildSocialButton(Icons.code, () => _openUrl('https://github.com')),
        SizedBox(width: 12),
        _buildSocialButton(Icons.web, () => _openUrl('https://twitter.com')),
        SizedBox(width: 12),
        _buildSocialButton(Icons.email, () => _openUrl('mailto:femi@tapr.example')),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onTap) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Material(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: Container(
                padding: EdgeInsets.all(12),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Projects', _stats['Projects']!),
        _buildDivider(),
        _buildStatItem('Followers', _stats['Followers']!),
        _buildDivider(),
        _buildStatItem('Students', _stats['Students']!),
      ],
    );
  }

  Widget _buildStatItem(String label, int value) {
    final isDark = widget.isDarkMode;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Column(
            children: [
              Text(
                _formatNumber(value),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildGradientButton(
            icon: Icons.download,
            label: 'Save contact',
            onTap: () async {
              HapticFeedback.mediumImpact();
              await _shareVCard();
            },
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildGradientButton(
            icon: Icons.swap_vert,
            label: 'Exchange',
            onTap: () {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📱 Exchange contact - Coming soon!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.deepPurple,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white),
                    SizedBox(width: 8),
                    Text(label, style: TextStyle(fontSize: 16, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: textColor,
      ),
    );
  }

  Widget _buildAboutText(bool isDark) {
    return Text(
      'Femi is a mobile app developer and educator based in Nigeria. He builds real world apps and teaches Flutter to beginners.',
      style: TextStyle(
        fontSize: 16,
        color: isDark ? Colors.grey[300] : Colors.black87,
        height: 1.45,
      ),
    );
  }

  Widget _buildSkillBars(bool isDark) {
    final skills = [
      {'name': 'Flutter / Dart', 'progress': 0.95},
      {'name': 'UI/UX Design', 'progress': 0.85},
      {'name': 'REST APIs & Firebase', 'progress': 0.90},
      {'name': 'Mobile Architecture', 'progress': 0.88},
    ];

    return Column(
      children: skills.map((skill) => _buildAnimatedProgressBar(skill, isDark)).toList(),
    );
  }

  Widget _buildAnimatedProgressBar(Map<String, dynamic> skill, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skill['name'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.black87,
                ),
              ),
              Text(
                '${(skill['progress'] * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: skill['progress']),
            duration: Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Stack(
                children: [
                  // Background
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Progress
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF667eea).withOpacity(0.4),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureWave(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 2000),
      builder: (context, value, child) {
        return CustomPaint(
          painter: WaveSignaturePainter(
            progress: value,
            color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
          ),
          size: Size(double.infinity, 60),
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link')),
      );
    }
  }
}

// Particle class for floating particles
class Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// Particle painter
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final bool isDark;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = (isDark ? Colors.white : Colors.white).withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      // Animate particle position
      final yOffset = (particle.y + progress * particle.speed) % 1.0;
      final xOffset = particle.x + sin(progress * 2 * pi + particle.x * 10) * 0.05;

      canvas.drawCircle(
        Offset(xOffset * size.width, yOffset * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Wave signature painter
class WaveSignaturePainter extends CustomPainter {
  final double progress;
  final Color color;

  WaveSignaturePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (int i = 0; i <= size.width.toInt(); i++) {
      final x = i.toDouble();
      final waveProgress = (i / size.width + progress) % 1.0;
      final y = size.height / 2 +
          sin(waveProgress * 2 * pi * 3) * 10 * (1 - (waveProgress - 0.5).abs() * 2);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WaveSignaturePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
