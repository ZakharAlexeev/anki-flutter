import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../decks/deck_list_screen.dart';
import '../stats/stats_screen.dart';
import '../theme/app_theme.dart';
import 'more_screen.dart';

/// Root of the app: an iOS tab bar with Decks / Statistics / More.
///
/// Tabs keep their state in an [IndexedStack]; each time a tab is
/// re-opened it gets a fresh [_visits] token so it can reload numbers that
/// may have changed elsewhere (a card added from "More", a study session).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _visits = [0, 0, 0];

  void _select(int i) {
    setState(() {
      _index = i;
      _visits[i]++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DeckListScreen(refreshToken: _visits[0]),
          StatsScreen(key: ValueKey('stats-${_visits[1]}'), title: 'Все колоды'),
          const MoreScreen(),
        ],
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: _index,
        onTap: _select,
        activeColor: context.accentForeground,
        inactiveColor: colors.muted,
        backgroundColor: colors.surface.withValues(alpha: 0.94),
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.rectangle_stack), label: 'Колоды'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.chart_bar), label: 'Статистика'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.ellipsis_circle), label: 'Ещё'),
        ],
      ),
    );
  }
}
