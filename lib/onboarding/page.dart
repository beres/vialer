import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'initial/form.dart';
import 'login/form.dart';
import 'widgets/background.dart';

class OnboardingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _duration = Duration(milliseconds: 400);
  static const _curve = Curves.decelerate;

  final _controller = PageController();

  List<Widget> _forms;

  void _forward() => _controller.nextPage(
        duration: _duration,
        curve: _curve,
      );

  Future<bool> _backward() async {
    if (_controller.page <= 0) {
      // Pop the page.
      return true;
    }

    _controller.previousPage(
      duration: _duration,
      curve: _curve,
    );

    return false;
  }

  @override
  void initState() {
    super.initState();

    _forms = [
      InitialForm(forward: _forward),
      LoginForm.create(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: WillPopScope(
          onWillPop: _backward,
          child: PageView(
            controller: _controller,
            children: _forms.map((f) {
              return SafeArea(
                child: Provider<EdgeInsets>(
                  create: (_) => EdgeInsets.all(48).copyWith(
                    top: 128,
                    bottom: 32,
                  ),
                  child: f,
                ),
              );
            }).toList(),
            physics: NeverScrollableScrollPhysics(),
          ),
        ),
      ),
    );
  }
}
