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
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _avatarScaleAnimation;
  late Animation<double> _avatarTapScaleAnimation;
  bool _isAvatarExpanded = false;

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

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _avatarTapController.dispose();
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
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/image1.jpg',
              fit: BoxFit.cover,
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
                      Text(
                        'tapr',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
                            onPressed: () => widget.onThemeChanged(!isDark),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white, width: 1.5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            onPressed: () {},
                            child: Text('Get your card'),
                          ),
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
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _toggleAvatarScale();
                        },
                        child: ScaleTransition(
                          scale: _avatarScaleAnimation,
                          child: ScaleTransition(
                            scale: _avatarTapScaleAnimation,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: AssetImage('assets/profile.png'),
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Femi Adeleke',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      TextButton(
                        onPressed: () async {
                          final url = Uri.parse('https://www.linkedin.com/in/adeleke-femi-48664b3b1?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not open LinkedIn profile')),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Mobile App Dev Guru',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
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
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Two buttons
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 62,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () async {
                                        HapticFeedback.mediumImpact();
                                        await _shareVCard();
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.download, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Save contact',
                                              style: TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 62,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () {
                                        HapticFeedback.mediumImpact();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Exchange contact tapped!')),
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.swap_vert, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Exchange contact',
                                              style: TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 22),
                            // About
                            Text(
                              'ABOUT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Femi is a mobile app developer and educator based in Nigeria. He builds real world apps and teaches Flutter to beginners.',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.grey[300] : Colors.black87,
                                height: 1.45,
                              ),
                            ),
                            SizedBox(height: 16),
                            // Expertise
                            Text(
                              'EXPERTISE',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• Flutter / Dart\n• UI/UX Design\n• REST APIs & Firebase\n• Mobile app architecture',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.grey[300] : Colors.black87,
                                height: 1.5,
                              ),
                            ),
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
}