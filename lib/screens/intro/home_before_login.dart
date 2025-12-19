import 'package:flutter/material.dart';

import '../login/login_screen.dart';
import '../login/register_screen.dart';

class HomeBeforeLogin extends StatefulWidget {
  const HomeBeforeLogin({super.key});

  @override
  State<HomeBeforeLogin> createState() => _HomeBeforeLoginState();
}

class _HomeBeforeLoginState extends State<HomeBeforeLogin> {
  final PageController _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardData(
      image: "assets/images/bb_anh1.png",
      title: "Luxury and Comfort,\nJust a Tap Away",
      desc:
      "Semper in cursus magna et eu varius nunc adipiscing. Elementum justo, laoreet id sem.",
      button: "Continue",
      showRegister: false,
    ),
    _OnboardData(
      image: "assets/images/bb_anh2.png",
      title: "Book with Ease, Stay\nwith Style",
      desc:
      "Semper in cursus magna et eu varius nunc adipiscing. Elementum justo, laoreet id sem.",
      button: "Continue",
      showRegister: false,
    ),
    _OnboardData(
      image: "assets/images/bb_anh3.png",
      title: "Discover Your Dream\nHotel, Effortlessly",
      desc:
      "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
      button: "Get Started",
      showRegister: true,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.animateToPage(
        _index + 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        itemCount: _pages.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final p = _pages[i];
          return _OnboardPage(
            data: p,
            pageIndex: i,
            currentIndex: _index,
            total: _pages.length,
            onNext: _next,
          );
        },
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final _OnboardData data;
  final int pageIndex;
  final int currentIndex;
  final int total;
  final VoidCallback onNext;

  const _OnboardPage({
    required this.data,
    required this.pageIndex,
    required this.currentIndex,
    required this.total,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ảnh nền
        Positioned.fill(
          child: Image.asset(
            data.image,
            fit: BoxFit.cover,
          ),
        ),

        // Lớp tối ở dưới giống ảnh
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.40),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Spacer(),

                // Title
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Desc
                Text(
                  data.desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),

                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(total, (i) {
                    final active = i == currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: active ? 18 : 6,
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF2F64D6) : Colors.white54,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 18),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F64D6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      data.button,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // Register line (chỉ trang cuối)
                if (data.showRegister) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don’t have an account? ",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            color: Color(0xFF2F64D6),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardData {
  final String image;
  final String title;
  final String desc;
  final String button;
  final bool showRegister;

  const _OnboardData({
    required this.image,
    required this.title,
    required this.desc,
    required this.button,
    required this.showRegister,
  });
}
