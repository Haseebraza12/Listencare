import 'package:flutter/material.dart';
import '../../captions/application/caption_controller.dart';
import '../domain/conversation.dart';
import '../../../theme/palette.dart';
import '../../../widgets/brand_mark.dart';
import '../../../widgets/design_components.dart';
import 'conversation_tile.dart';

class ConversationPanel extends StatefulWidget {
  const ConversationPanel({
    super.key,
    required this.controller,
    required this.onNavigate,
    required this.onSettings,
    required this.onOpenConversation,
  });
  final CaptionController controller;
  final void Function(int) onNavigate;
  final VoidCallback onSettings;
  final void Function(Conversation) onOpenConversation;
  @override
  State<ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends State<ConversationPanel> {
  CaptionController get c => widget.controller;
  void _go(int tab) => widget.onNavigate(tab);
  void _settings() => widget.onSettings();
  Widget _header({
    String? title,
    Widget? leading,
    required List<Widget> actions,
  }) => PanelHeader(
    title: title,
    leading: leading,
    actions: actions,
    onBack: () => _go(1),
  );
  Widget _noteTile(Conversation note) => ConversationTile(
    conversation: note,
    onOpen: () => widget.onOpenConversation(note),
  );
  int _period = 0;
  @override
  Widget build(BuildContext context) => _overview();
  List<Conversation> get _periodNotes {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = _period == 1
        ? today
        : _period == 2
        ? DateTime(now.year, now.month)
        : today.subtract(Duration(days: now.weekday - 1));
    return c.conversations
        .where((note) => !note.createdAt.isBefore(start))
        .toList();
  }

  Widget _overview() {
    final notes = _periodNotes;
    final seconds = notes.fold<int>(
      0,
      (sum, item) => sum + item.durationSeconds,
    );
    const weekdays = [6, 7, 1, 2, 3, 4, 5];
    const dayLabels = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    const dayColors = [
      Palette.pink,
      Color(0xFF35ACE8),
      Palette.gold,
      Color(0xFFBCABF5),
      Color(0xFFA9D7CE),
      Color(0xFFEDBAA0),
      Color(0xFFB5C7EE),
    ];
    final dayCounts = weekdays
        .map(
          (day) => notes.where((note) => note.createdAt.weekday == day).length,
        )
        .toList();
    return Column(
      children: [
        _header(
          leading: const BrandMark(size: 48),
          actions: [
            CircleAction(
              icon: Icons.search_rounded,
              label: 'Search conversations',
              onPressed: () => _go(2),
            ),
            const SizedBox(width: 12),
            CircleAction(
              icon: Icons.tune_rounded,
              label: 'Settings',
              onPressed: _settings,
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            children: [
              Text(
                'Your conversations',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinePill(
                      label: 'Weekly',
                      icon: Icons.trending_up_rounded,
                      selected: _period == 0,
                      onTap: () => setState(() => _period = 0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinePill(
                      label: 'Daily',
                      icon: Icons.track_changes_rounded,
                      selected: _period == 1,
                      onTap: () => setState(() => _period = 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinePill(
                      label: 'Monthly',
                      icon: Icons.bolt_outlined,
                      selected: _period == 2,
                      onTap: () => setState(() => _period = 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'A little more connected',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 21,
                          color: Palette.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Be present in every conversation.\nWe’ll take care of the words.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: Palette.gradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${notes.length} saved conversations',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const Text(
                          'On this device',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Conversation activity',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Icon(Icons.calendar_month_outlined, size: 21),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(DateTime.now()),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: _metric('Conversations', '${notes.length}'),
                        ),
                        Expanded(
                          child: _metric(
                            'Time connected',
                            '${seconds ~/ 60} min',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 20,
                        child: Row(
                          children: notes.isEmpty
                              ? [
                                  Expanded(
                                    child: Container(color: Colors.white),
                                  ),
                                ]
                              : [
                                  for (var day = 0; day < 7; day++)
                                    if (dayCounts[day] > 0)
                                      Expanded(
                                        flex: dayCounts[day],
                                        child: Container(color: dayColors[day]),
                                      ),
                                ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (var row = 0; row < 4; row++)
                      SizedBox(
                        height: 29,
                        child: Row(
                          children: [
                            Expanded(
                              child: _legend(
                                dayLabels[row],
                                dayCounts[row],
                                dayColors[row],
                              ),
                            ),
                            Expanded(
                              child: row + 4 < 7
                                  ? _legend(
                                      dayLabels[row + 4],
                                      dayCounts[row + 4],
                                      dayCounts[row + 4] == 0
                                          ? Colors.white
                                          : dayColors[row + 4],
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent conversations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _go(2),
                    child: const Text('See all'),
                  ),
                ],
              ),
              if (c.conversations.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      const Text(
                        'A new connection starts with a word.',
                        style: TextStyle(color: Palette.muted),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _go(1),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Start a conversation'),
                      ),
                    ],
                  ),
                )
              else
                ...c.conversations.take(3).map(_noteTile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metric(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontSize: 27, letterSpacing: -1)),
    ],
  );
  Widget _legend(String label, int value, Color color) => Row(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 9),
      Text(label, style: const TextStyle(fontSize: 12)),
      const Spacer(),
      Text(
        value.toString().padLeft(2, '0'),
        style: const TextStyle(fontSize: 12),
      ),
      const SizedBox(width: 14),
    ],
  );
}
