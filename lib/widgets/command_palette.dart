// import 'dart:ui';

// import 'package:flutter/material.dart';
// import '../data/profile.dart';

// class CommandPalette {
//   static Future<void> show(
//     BuildContext context, {
//     required void Function(String id) onNavigate,
//   }) async {
//     final entries = <_Entry>[
//       _Entry('home', 'Go Home', Icons.home_rounded),
//       _Entry('projects', 'Open Projects', Icons.auto_awesome),
//       _Entry('playground', 'Open Playground', Icons.toys),
//       _Entry('about', 'Open About', Icons.person),
//       _Entry('contact', 'Open Contact', Icons.mail_outline),
//       _Entry('link:github', 'Open GitHub', Icons.code, url: Profile.github),
//       _Entry(
//         'link:linkedin',
//         'Open LinkedIn',
//         Icons.person,
//         url: Profile.linkedin,
//       ),
//       if (Profile.twitter.isNotEmpty)
//         _Entry(
//           'link:twitter',
//           'Open Twitter / X',
//           Icons.chat_bubble_outline,
//           url: Profile.twitter,
//         ),
//     ];

//     String query = '';
//     int selected = 0;

//     await showGeneralDialog(
//       context: context,
//       barrierDismissible: true,
//       barrierLabel: 'CommandPalette',
//       pageBuilder: (_, __, ___) {
//         return _PaletteScaffold(entries: entries, onNavigate: onNavigate);
//       },
//     );
//   }
// }

// class _PaletteScaffold extends StatefulWidget {
//   const _PaletteScaffold({required this.entries, required this.onNavigate});
//   final List<_Entry> entries;
//   final void Function(String id) onNavigate;

//   @override
//   State<_PaletteScaffold> createState() => _PaletteScaffoldState();
// }

// class _PaletteScaffoldState extends State<_PaletteScaffold> {
//   final _controller = TextEditingController();
//   final _focus = FocusNode();
//   int _sel = 0;

//   List<Object> get _filtered {
//     final q = _controller.text.trim().toLowerCase();
//     if (q.isEmpty) return widget.entries;
//     return widget.entries
//         .map((e) => MapEntry(_score(e, q), e))
//         .where((p) => p.key > 0)
//         .toList()
//       ..sort((a, b) => b.key.compareTo(a.key));
//   }

//   int _score(_Entry e, String q) {
//     final hay = (e.label + ' ' + (e.url ?? '')).toLowerCase();
//     if (hay.contains(q)) return 10 + (q.length);
//     int pts = 0;
//     for (final ch in q.split('')) {
//       if (hay.contains(ch)) pts++;
//     }
//     return pts; // tiny fuzzy
//   }

//   @override
//   void initState() {
//     super.initState();
//     // Autofocus when opening
//     WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
//   }

//   void _trigger(_Entry e) {
//     if (e.id.startsWith('link:') && e.url != null) {
//       // return URL to caller via Navigator so they can launch it (keeps URL launcher in one place)
//       Navigator.of(context).pop(e.url);
//       return;
//     }
//     widget.onNavigate(e.id);
//     Navigator.of(context).pop();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final items = _filtered;
//     if (_sel >= items.length) _sel = (items.isEmpty ? 0 : items.length - 1);

//     return Material(
//       type: MaterialType.transparency,
//       child: Stack(
//         children: [
//           // Frosted backdrop
//           Positioned.fill(
//             child: GestureDetector(
//               onTap: () => Navigator.of(context).pop(),
//               child: Container(color: Colors.black.withOpacity(.35)),
//             ),
//           ),
//           // Dialog
//           Center(
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(16),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
//                 child: Container(
//                   width: 720,
//                   constraints: const BoxConstraints(maxWidth: 720),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(.35),
//                     border: Border.all(color: Colors.white12),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // input
//                       Padding(
//                         padding: const EdgeInsets.all(14.0),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.search, size: 18),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: RawKeyboardListener(
//                                 focusNode: _focus,
//                                 onKey: (e) {
//                                   if (e.isKeyPressed(
//                                     LogicalKeyboardKey.escape,
//                                   )) {
//                                     Navigator.of(context).pop();
//                                   }
//                                   if (e.isKeyPressed(
//                                     LogicalKeyboardKey.arrowDown,
//                                   )) {
//                                     setState(
//                                       () => _sel = (_sel + 1).clamp(
//                                         0,
//                                         _filtered.length - 1,
//                                       ),
//                                     );
//                                   }
//                                   if (e.isKeyPressed(
//                                     LogicalKeyboardKey.arrowUp,
//                                   )) {
//                                     setState(
//                                       () => _sel = (_sel - 1).clamp(
//                                         0,
//                                         _filtered.length - 1,
//                                       ),
//                                     );
//                                   }
//                                   if (e.isKeyPressed(
//                                     LogicalKeyboardKey.enter,
//                                   )) {
//                                     if (_filtered.isNotEmpty)
//                                       _trigger(_filtered[_sel]);
//                                   }
//                                 },
//                                 child: TextField(
//                                   controller: _controller,
//                                   decoration: const InputDecoration(
//                                     hintText: 'Jump to…  (⌘/Ctrl + K)',
//                                     border: InputBorder.none,
//                                   ),
//                                   onChanged: (_) => setState(() {}),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const Divider(height: 1, color: Colors.white10),
//                       ConstrainedBox(
//                         constraints: const BoxConstraints(maxHeight: 400),
//                         child: ListView.builder(
//                           shrinkWrap: true,
//                           itemCount: items.length,
//                           itemBuilder: (_, i) {
//                             final e = items[i];
//                             final selected = i == _sel;
//                             return InkWell(
//                               onTap: () => _trigger(e),
//                               child: Container(
//                                 color: selected
//                                     ? Colors.white.withOpacity(.06)
//                                     : Colors.transparent,
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 14,
//                                   vertical: 12,
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Icon(
//                                       e.icon,
//                                       size: 18,
//                                       color: Colors.white70,
//                                     ),
//                                     const SizedBox(width: 10),
//                                     Expanded(child: Text(e.label)),
//                                     if (e.url != null)
//                                       Text(
//                                         e.url!,
//                                         style: const TextStyle(
//                                           color: Colors.white38,
//                                           fontSize: 12,
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Entry {
//   final String id;
//   final String label;
//   final IconData icon;
//   final String? url;
//   _Entry(this.id, this.label, this.icon, {this.url});
// }
