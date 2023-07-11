import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import '../../../../resources/localizations.dart';
import '../cubit.dart';
import '../widgets/buttons/settings_button.dart';
import '../widgets/tile/mobile_number.dart';
import '../widgets/tile/outgoing_number.dart';
import '../widgets/tile/username.dart';
import 'widget.dart';

class UserSubPage extends StatelessWidget {
  const UserSubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SettingsSubPage(
          cubit: context.watch<SettingsCubit>(),
          title:
              context.msg.main.settings.subPage.user.title(state.user.fullName),
          child: (state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      MobileNumberTile(state.user),
                      OutgoingNumberTile(
                        state.user,
                        enabled: state.shouldAllowRemoteSettings,
                        recentOutgoingNumbers: state.recentOutgoingNumbers,
                      ),
                      UsernameTile(state.user),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                KeyboardVisibilityBuilder(
                  builder: (context, isKeyboardVisible) {
                    return Visibility(
                      visible: !isKeyboardVisible,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SettingsButton(
                          text: context.msg.main.settings.buttons.logout,
                          onPressed: () => unawaited(
                            context.read<SettingsCubit>().logout(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }
}
