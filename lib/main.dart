import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const EagleApp());
}

// ═══════════════════════════════════════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════════════════════════════════════

const kBg = Color(0xFF0E1A29);
const kDeepBg = Color(0xFF091522);
const kCard = Color(0xFF17263A);
const kCardBorder = Color(0xFF253B54);
const kInput = Color(0xFF0D1C2B);

const kYellow = Color(0xFFFFED19);
const kYellowDark = Color(0xFFB7A900);

const kGreen = Color(0xFF39D86A);
const kGreenDark = Color(0xFF0B351C);

const kBlue = Color(0xFF2196F3);
const kBlueDark = Color(0xFF0D3154);

const kRed = Color(0xFFFF4545);
const kRedDark = Color(0xFF3C1014);

const kOrange = Color(0xFFFFB020);
const kOrangeDark = Color(0xFF664000);

const kText = Color(0xFFE8F0F6);
const kTextMuted = Color(0xFF86A1B7);
const kMuted = Color(0xFF55758F);
const kGrid = Color(0xFF31516B);

// ═══════════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class PitchMovement {
  String name;
  double? velo;
  double? vert;
  double? horz;
  bool active;

  PitchMovement({
    required this.name,
    this.velo,
    this.vert,
    this.horz,
    required this.active,
  });

  PitchMovement copyWith({
    String? name,
    double? velo,
    double? vert,
    double? horz,
    bool? active,
    bool clearVelo = false,
    bool clearVert = false,
    bool clearHorz = false,
  }) {
    return PitchMovement(
      name: name ?? this.name,
      velo: clearVelo ? null : (velo ?? this.velo),
      vert: clearVert ? null : (vert ?? this.vert),
      horz: clearHorz ? null : (horz ?? this.horz),
      active: active ?? this.active,
    );
  }
}

class Recommendation {
  final String pitch;
  final String location;
  final double score;
  final bool chase;

  const Recommendation({
    required this.pitch,
    required this.location,
    required this.score,
    required this.chase,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP
// ═══════════════════════════════════════════════════════════════════════════════

class EagleApp extends StatelessWidget {
  const EagleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E.A.G.L.E. PitchCall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBg,
        colorScheme: ColorScheme.dark(
          primary: kYellow,
          secondary: kGreen,
        ),
      ),
      home: const PitchCallScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class PitchCallScreen extends StatefulWidget {
  const PitchCallScreen({super.key});

  @override
  State<PitchCallScreen> createState() => _PitchCallScreenState();
}

class _PitchCallScreenState extends State<PitchCallScreen> {
  // ────────────────────────────────────────────────────────────────────────────
  // GAME STATE
  // ────────────────────────────────────────────────────────────────────────────

  int balls = 0;
  int strikes = 0;
  int pitchCount = 0;

  String pitcherHand = 'Right';
  String batterSide = 'Righty';

  String? timing;
  String? lastPitchResult;
  String? pitchJustThrown;

  double velocity = 80;

  Offset? pitchLocation;

  int atBat = 1;

  List<PitchMovement> movements = [];

  List<Recommendation> recommendations = [];

  // ────────────────────────────────────────────────────────────────────────────
  // INITIALIZE EMPTY PITCH TABLE
  // ────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    movements = _emptyMovementRows();
  }

  List<PitchMovement> _emptyMovementRows() {
    return List.generate(
      8,
      (i) => PitchMovement(
        name: 'Enter pitch',
        active: false,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _newAtBat() {
    setState(() {
      balls = 0;
      strikes = 0;
      atBat++;

      timing = null;
      lastPitchResult = null;
      pitchJustThrown = null;
      pitchLocation = null;

      recommendations = [];
    });
  }

  void _newPitcher() {
    setState(() {
      balls = 0;
      strikes = 0;
      pitchCount = 0;
      atBat = 1;

      pitcherHand = 'Right';
      batterSide = 'Righty';

      timing = null;
      lastPitchResult = null;
      pitchJustThrown = null;
      pitchLocation = null;

      velocity = 80;

      movements = _emptyMovementRows();
      recommendations = [];
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GO BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  void _go() {
    if (lastPitchResult == null) {
      _showMessage(
        'Select what happened on the last pitch first.',
      );
      return;
    }

    final activePitches = movements
        .where((m) => m.active && m.name.trim().isNotEmpty)
        .toList();

    if (activePitches.isEmpty) {
      _showMessage(
        'Enter at least one pitch in the pitcher movement table.',
      );
      return;
    }

    _recordPitchResult();

    final generated = RecommendationEngine.generate(
      pitches: activePitches,
      balls: balls,
      strikes: strikes,
      pitchCount: pitchCount,
      timing: timing,
      lastResult: lastPitchResult,
      pitchLocation: pitchLocation,
      pitcherHand: pitcherHand,
      batterSide: batterSide,
    );

    setState(() {
      recommendations = generated;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECORD LAST PITCH + UPDATE COUNT
  // ═══════════════════════════════════════════════════════════════════════════

  void _recordPitchResult() {
    final result = lastPitchResult;

    setState(() {
      pitchCount++;

      switch (result) {
        case 'Ball':
          if (balls < 3) {
            balls++;
          } else {
            // Four balls → new at-bat.
            balls = 0;
            strikes = 0;
            atBat++;
          }
          break;

        case 'Called Strike':
        case 'Swinging Strike':
          if (strikes < 2) {
            strikes++;
          } else {
            // Strike three → new at-bat.
            balls = 0;
            strikes = 0;
            atBat++;
          }
          break;

        case 'Foul':
          // Fouls cannot increase strikes beyond two.
          if (strikes < 2) {
            strikes++;
          }
          break;

        case 'In Play':
          // Treat the ball in play as the end of the at-bat.
          balls = 0;
          strikes = 0;
          atBat++;
          break;
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: kCard,
        ),
      );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOVEMENT TABLE
  // ═══════════════════════════════════════════════════════════════════════════

  void _setPitchName(int index, String name) {
    final cleaned = name.trim();

    setState(() {
      movements[index] = movements[index].copyWith(
        name: cleaned.isEmpty ? 'Enter pitch' : cleaned,
        active: cleaned.isNotEmpty,
      );

      // If this is the first pitch entered, automatically select it.
      if (cleaned.isNotEmpty && pitchJustThrown == null) {
        pitchJustThrown = cleaned;
      }
    });
  }

  void _setMovementValue(
    int index,
    String field,
    double? value,
  ) {
    setState(() {
      final current = movements[index];

      if (field == 'velo') {
        movements[index] = current.copyWith(
          velo: value,
          clearVelo: value == null,
        );
      } else if (field == 'vert') {
        movements[index] = current.copyWith(
          vert: value,
          clearVert: value == null,
        );
      } else if (field == 'horz') {
        movements[index] = current.copyWith(
          horz: value,
          clearHorz: value == null,
        );
      }
    });
  }

  void _addPitchRow() {
    setState(() {
      movements.add(
        PitchMovement(
          name: 'Enter pitch',
          active: false,
        ),
      );
    });
  }

  void _removePitchRow(int index) {
    setState(() {
      final removed = movements[index].name;

      movements.removeAt(index);

      if (pitchJustThrown == removed) {
        pitchJustThrown = null;
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: math.max(width, 1180),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 370,
                          child: _leftColumn(),
                        ),
                        Expanded(
                          child: _rightColumn(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _header() {
    final status = _pitchLimitStatus();

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: kDeepBg,
        border: Border(
          bottom: BorderSide(color: kCardBorder),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'E.A.G.L.E.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'PITCHCALL',
            style: TextStyle(
              color: kMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),

          const Spacer(),

          // PITCH COUNT
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: status.background,
              border: Border.all(
                color: status.border,
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                Text(
                  'PITCHES',
                  style: TextStyle(
                    color: status.foreground.withOpacity(.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  '$pitchCount',
                  style: TextStyle(
                    color: status.foreground,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          _headerButton(
            'New At-Bat',
            Icons.refresh,
            _newAtBat,
            const Color(0xFF1B3147),
            const Color(0xFF34546E),
            Colors.white,
          ),

          const SizedBox(width: 8),

          _headerButton(
            'New Pitcher',
            Icons.person_add_alt_1,
            _newPitcher,
            kGreenDark,
            const Color(0xFF23683B),
            kGreen,
          ),
        ],
      ),
    );
  }

  Widget _headerButton(
    String text,
    IconData icon,
    VoidCallback onTap,
    Color background,
    Color border,
    Color foreground,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: foreground,
            ),
            const SizedBox(width: 7),
            Text(
              text,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PITCH LIMIT STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  _PitchStatus _pitchLimitStatus() {
    if (pitchCount >= 60) {
      return const _PitchStatus(
        background: kRedDark,
        border: Color(0xFF8B2828),
        foreground: kRed,
      );
    }

    if (pitchCount >= 20) {
      return const _PitchStatus(
        background: Color(0xFF4A4015),
        border: Color(0xFF827021),
        foreground: kYellow,
      );
    }

    return const _PitchStatus(
      background: kBlueDark,
      border: Color(0xFF23649B),
      foreground: Color(0xFF55B4FF),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEFT COLUMN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _leftColumn() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _strikeZonePanel(),

          const SizedBox(height: 10),

          _velocityPanel(),

          const SizedBox(height: 10),

          _countPanel(),

          const SizedBox(height: 10),

          _handednessPanel(),

          const SizedBox(height: 10),

          _lastPitchResultPanel(),

          const SizedBox(height: 10),

          _goButton(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STRIKE ZONE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _strikeZonePanel() {
    return _panel(
      Column(
        children: [
          const Center(
            child: Text(
              'BATTER & LAST PITCH LOCATION',
              style: TextStyle(
                color: kTextMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _batterSideButton('Righty'),
              const SizedBox(width: 8),

              Expanded(
                child: StrikeZoneWidget(
                  pitchDot: pitchLocation,
                  onTap: (location) {
                    setState(() {
                      pitchLocation = location;
                    });
                  },
                ),
              ),

              const SizedBox(width: 8),

              _batterSideButton('Lefty'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _batterSideButton(String side) {
    final selected = batterSide == side;

    return GestureDetector(
      onTap: () {
        setState(() {
          batterSide = side;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30,
        height: 145,
        decoration: BoxDecoration(
          color: selected ? kYellow : const Color(0xFF1C3147),
          borderRadius: BorderRadius.circular(5),
          border: selected
              ? null
              : Border.all(
                  color: const Color(0xFF31506A),
                ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: kYellow.withOpacity(.25),
                    blurRadius: 15,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              side.toUpperCase(),
              style: TextStyle(
                color: selected ? kDeepBg : kMuted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.7,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VELOCITY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _velocityPanel() {
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('Velocity — Pitch Just Thrown'),
              Row(
                children: [
                  Text(
                    '${velocity.round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text(
                    'MPH',
                    style: TextStyle(
                      color: kMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          SizedBox(
            height: 38,
            child: CustomPaint(
              painter: VeloRulerPainter(
                velocity: velocity,
              ),
              size: const Size(
                double.infinity,
                38,
              ),
            ),
          ),

          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbColor: kYellow,
              activeTrackColor: kYellowDark,
              inactiveTrackColor: const Color(0xFF2C4057),
              overlayColor: kYellow.withOpacity(.15),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
              ),
            ),
            child: Slider(
              min: 60,
              max: 100,
              value: velocity,
              onChanged: (value) {
                setState(() {
                  velocity = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COUNT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _countPanel() {
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('COUNT'),

          const SizedBox(height: 9),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: kInput,
              border: Border.all(
                color: const Color(0xFF29445E),
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _countControl(
                    'BALLS',
                    balls,
                    3,
                    (value) {
                      setState(() {
                        balls = value;
                      });
                    },
                  ),
                ),

                Container(
                  width: 1,
                  height: 45,
                  color: const Color(0xFF2B4056),
                ),

                Expanded(
                  child: _countControl(
                    'STRIKES',
                    strikes,
                    2,
                    (value) {
                      setState(() {
                        strikes = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _countControl(
    String label,
    int value,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kMuted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _smallButton(
              Icons.remove,
              () {
                onChanged(
                  math.max(0, value - 1),
                );
              },
            ),

            const SizedBox(width: 13),

            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(width: 13),

            _smallButton(
              Icons.add,
              () {
                onChanged(
                  math.min(max, value + 1),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _smallButton(
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF1D354B),
          border: Border.all(
            color: const Color(0xFF365772),
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(
          icon,
          color: kYellow,
          size: 17,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HAND
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _handednessPanel() {
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('PITCHER HANDEDNESS'),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: _handButton('Left'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _handButton('Right'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _handButton(String hand) {
    final selected = pitcherHand == hand;

    return GestureDetector(
      onTap: () {
        setState(() {
          pitcherHand = hand;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected ? kYellow : const Color(0xFF1D344A),
          borderRadius: BorderRadius.circular(6),
          border: selected
              ? null
              : Border.all(
                  color: const Color(0xFF36546E),
                ),
        ),
        child: Center(
          child: Text(
            hand,
            style: TextStyle(
              color: selected ? kDeepBg : kTextMuted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAST PITCH RESULT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _lastPitchResultPanel() {
    const results = [
      'Ball',
      'Called Strike',
      'Swinging Strike',
      'Foul',
      'In Play',
    ];

    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('LAST PITCH RESULT'),
              const Text(
                'record what happened',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: results.map((result) {
              final selected = lastPitchResult == result;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    lastPitchResult = result;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? kYellow
                        : const Color(0xFF1C354B),
                    border: Border.all(
                      color: selected
                          ? kYellow
                          : const Color(0xFF36566F),
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    result,
                    style: TextStyle(
                      color: selected
                          ? kDeepBg
                          : kTextMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GO BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _goButton() {
    return GestureDetector(
      onTap: _go,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: kYellow,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: kYellow.withOpacity(.22),
              blurRadius: 30,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GO',
              style: TextStyle(
                color: kDeepBg,
                fontSize: 52,
                fontWeight: FontWeight.w900,
                height: .9,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'RECORD RESULT  •  GET NEXT PITCH',
              style: TextStyle(
                color: kDeepBg.withOpacity(.58),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RIGHT COLUMN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _rightColumn() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        12,
        12,
        12,
      ),
      child: Column(
        children: [
          _timingPanel(),

          const SizedBox(height: 10),

          _pitchTypePanel(),

          const SizedBox(height: 10),

          _movementPanel(),

          const SizedBox(height: 10),

          _recommendationPanel(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMING
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _timingPanel() {
    const options = [
      'Early',
      'Late',
      'On Time',
      'Unknown',
    ];

    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('TIMING'),

          const SizedBox(height: 9),

          Row(
            children: options.map((option) {
              final selected = timing == option;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: option == options.first ? 0 : 6,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        timing = option;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? kYellow
                            : const Color(0xFF1C344A),
                        borderRadius: BorderRadius.circular(6),
                        border: selected
                            ? null
                            : Border.all(
                                color: const Color(0xFF36536C),
                              ),
                      ),
                      child: Center(
                        child: Text(
                          option,
                          style: TextStyle(
                            color: selected
                                ? kDeepBg
                                : kTextMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PITCH TYPE JUST THROWN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _pitchTypePanel() {
    final active = movements
        .where((m) => m.active && m.name.trim().isNotEmpty)
        .toList();

    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('PITCH TYPE — JUST THROWN'),
              const Text(
                'auto-created from movement table',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          if (active.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: kInput,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: kCardBorder,
                ),
              ),
              child: const Center(
                child: Text(
                  'Enter pitch types in the movement table below.',
                  style: TextStyle(
                    color: kMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: active.map((pitch) {
                final selected =
                    pitchJustThrown == pitch.name;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      pitchJustThrown = pitch.name;

                      if (pitch.velo != null) {
                        velocity = pitch.velo!;
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? kYellow
                          : const Color(0xFF1C344A),
                      borderRadius: BorderRadius.circular(5),
                      border: selected
                          ? null
                          : Border.all(
                              color: const Color(0xFF36536C),
                            ),
                    ),
                    child: Text(
                      pitch.name,
                      style: TextStyle(
                        color: selected
                            ? kDeepBg
                            : kTextMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOVEMENT TABLE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _movementPanel() {
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('PITCHER AVERAGE MOVEMENTS'),
              const Text(
                'set pregame • tap any cell',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Table(
              border: TableBorder.all(
                color: kCardBorder,
                width: .5,
              ),
              columnWidths: const {
                0: FlexColumnWidth(2.4),
                1: FlexColumnWidth(1.3),
                2: FlexColumnWidth(1.3),
                3: FlexColumnWidth(1.3),
                4: FixedColumnWidth(35),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: kDeepBg,
                  ),
                  children: [
                    _tableHeader(
                      'PITCH',
                      TextAlign.left,
                    ),
                    _tableHeader(
                      'VELO (MPH)',
                      TextAlign.center,
                    ),
                    _tableHeader(
                      'VERT (INCH)',
                      TextAlign.center,
                    ),
                    _tableHeader(
                      'HORZ (INCH)',
                      TextAlign.center,
                    ),
                    const SizedBox(height: 31),
                  ],
                ),

                ...movements.asMap().entries.map((entry) {
                  final index = entry.key;
                  final movement = entry.value;

                  return TableRow(
                    decoration: BoxDecoration(
                      color: index.isEven
                          ? kCard
                          : const Color(0xFF142338),
                    ),
                    children: [
                      PitchNameCell(
                        name: movement.name,
                        active: movement.active,
                        onSave: (name) {
                          _setPitchName(
                            index,
                            name,
                          );
                        },
                      ),

                      NumberCell(
                        value: movement.velo,
                        active: movement.active,
                        onSave: (value) {
                          _setMovementValue(
                            index,
                            'velo',
                            value,
                          );
                        },
                      ),

                      NumberCell(
                        value: movement.vert,
                        active: movement.active,
                        onSave: (value) {
                          _setMovementValue(
                            index,
                            'vert',
                            value,
                          );
                        },
                      ),

                      NumberCell(
                        value: movement.horz,
                        active: movement.active,
                        onSave: (value) {
                          _setMovementValue(
                            index,
                            'horz',
                            value,
                          );
                        },
                      ),

                      GestureDetector(
                        onTap: () {
                          _removePitchRow(index);
                        },
                        child: Container(
                          height: 45,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Color(0xFF496177),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          GestureDetector(
            onTap: _addPitchRow,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 11,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF34526D),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    size: 15,
                    color: kMuted,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Add Pitch Type',
                    style: TextStyle(
                      color: kMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECOMMENDATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _recommendationPanel() {
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel(
                'NEXT PITCH RECOMMENDATIONS',
              ),

              const SizedBox(width: 9),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: recommendations.isEmpty
                      ? const Color(0xFF26394B)
                      : kGreenDark,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: recommendations.isEmpty
                        ? const Color(0xFF3A536B)
                        : const Color(0xFF21723B),
                  ),
                ),
                child: Text(
                  recommendations.isEmpty
                      ? 'WAITING'
                      : 'ENGINE ACTIVE',
                  style: TextStyle(
                    color: recommendations.isEmpty
                        ? kMuted
                        : kGreen,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          if (recommendations.isEmpty)
            _emptyRecommendations()
          else
            _recommendationTable(),
        ],
      ),
    );
  }

  Widget _emptyRecommendations() {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: kInput,
        border: Border.all(
          color: kCardBorder,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            color: kMuted,
            size: 27,
          ),
          SizedBox(height: 8),
          Text(
            'No recommendations yet',
            style: TextStyle(
              color: kTextMuted,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Enter the last-pitch information and press GO.',
            style: TextStyle(
              color: kMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendationTable() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Table(
        border: TableBorder.all(
          color: kCardBorder,
          width: .5,
        ),
        columnWidths: const {
          0: FixedColumnWidth(55),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(2.1),
          3: FixedColumnWidth(95),
          4: FixedColumnWidth(90),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: kDeepBg,
            ),
            children: [
              _tableHeader('#', TextAlign.center),
              _tableHeader(
                'PITCH TYPE',
                TextAlign.left,
              ),
              _tableHeader(
                'LOCATION',
                TextAlign.left,
              ),
              _tableHeader(
                'SCORE',
                TextAlign.center,
              ),
              _tableHeader(
                'STRIKE / CHASE',
                TextAlign.center,
              ),
            ],
          ),

          ...recommendations.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final rec = entry.value;

              return TableRow(
                decoration: BoxDecoration(
                  color: index == 0
                      ? const Color(0xFF1A2D42)
                      : kCard,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                    ),
                    child: Center(
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? kYellow
                              : const Color(0xFF20384F),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: index == 0
                                  ? kDeepBg
                                  : kTextMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 13,
                    ),
                    child: Text(
                      rec.pitch,
                      style: TextStyle(
                        color: index == 0
                            ? kYellow
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    child: Text(
                      rec.location,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    child: Center(
                      child: Text(
                        '${rec.score.round()}%',
                        style: TextStyle(
                          color: rec.score >= 80
                              ? kGreen
                              : rec.score >= 65
                                  ? kYellow
                                  : kTextMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                    ),
                    child: Center(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: rec.chase
                              ? kRedDark
                              : kGreenDark,
                          borderRadius:
                              BorderRadius.circular(4),
                          border: Border.all(
                            color: rec.chase
                                ? const Color(0xFF7B2424)
                                : const Color(0xFF24723C),
                          ),
                        ),
                        child: Text(
                          rec.chase
                              ? 'CHASE'
                              : 'STRIKE',
                          style: TextStyle(
                            color: rec.chase
                                ? kRed
                                : kGreen,
                            fontSize: 9,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED UI
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _panel(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: kCard,
        border: Border.all(
          color: kCardBorder,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: kTextMuted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _tableHeader(
    String text,
    TextAlign alignment,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 9,
      ),
      child: Text(
        text,
        textAlign: alignment,
        style: const TextStyle(
          color: kMuted,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STRIKE ZONE — 3 × 3
// ═══════════════════════════════════════════════════════════════════════════════

class StrikeZoneWidget extends StatelessWidget {
  final Offset? pitchDot;
  final ValueChanged<Offset> onTap;

  const StrikeZoneWidget({
    super.key,
    required this.pitchDot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 1.15,
      child: GestureDetector(
        onTapDown: (details) {
          final box =
              context.findRenderObject() as RenderBox;

          final local =
              box.globalToLocal(details.globalPosition);

          onTap(
            Offset(
              local.dx / box.size.width,
              local.dy / box.size.height,
            ),
          );
        },
        child: CustomPaint(
          painter: StrikeZonePainter(
            pitchDot,
          ),
        ),
      ),
    );
  }
}

class StrikeZonePainter extends CustomPainter {
  final Offset? dot;

  StrikeZonePainter(this.dot);

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(5),
      ),
      Paint()..color = kInput,
    );

    final left = w * .18;
    final top = h * .12;
    final width = w * .64;
    final height = h * .63;

    final zonePaint = Paint()
      ..color = const Color(0xFF4C7592)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRect(
      Rect.fromLTWH(
        left,
        top,
        width,
        height,
      ),
      zonePaint,
    );

    // 3 × 3 GRID
    final gridPaint = Paint()
      ..color = kGrid
      ..strokeWidth = .8;

    for (int i = 1; i <= 2; i++) {
      final x = left + width * i / 3;

      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + height),
        gridPaint,
      );

      final y = top + height * i / 3;

      canvas.drawLine(
        Offset(left, y),
        Offset(left + width, y),
        gridPaint,
      );
    }

    // Home plate
    final cx = w / 2;
    final plateTop = h * .86;
    final plateWidth = w * .25;

    final plate = Path()
      ..moveTo(
        cx - plateWidth / 2,
        plateTop,
      )
      ..lineTo(
        cx + plateWidth / 2,
        plateTop,
      )
      ..lineTo(
        cx + plateWidth / 2,
        plateTop + h * .05,
      )
      ..lineTo(
        cx,
        plateTop + h * .10,
      )
      ..lineTo(
        cx - plateWidth / 2,
        plateTop + h * .05,
      )
      ..close();

    canvas.drawPath(
      plate,
      Paint()
        ..color = const Color(0xFF4C7592)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    if (dot != null) {
      final dx = dot!.dx * w;
      final dy = dot!.dy * h;

      canvas.drawCircle(
        Offset(dx, dy),
        12,
        Paint()
          ..color = kYellow.withOpacity(.25)
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            8,
          ),
      );

      canvas.drawCircle(
        Offset(dx, dy),
        6,
        Paint()..color = kYellow,
      );
    }
  }

  @override
  bool shouldRepaint(
    StrikeZonePainter oldDelegate,
  ) {
    return oldDelegate.dot != dot;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VELOCITY RULER
// ═══════════════════════════════════════════════════════════════════════════════

class VeloRulerPainter extends CustomPainter {
  final double velocity;

  VeloRulerPainter({
    required this.velocity,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    const min = 60.0;
    const max = 100.0;

    final ticks = [
      60,
      65,
      70,
      75,
      80,
      85,
      90,
      95,
      100,
    ];

    final y = 11.0;

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = const Color(0xFF31465B)
        ..strokeWidth = 1,
    );

    for (final tick in ticks) {
      final x =
          ((tick - min) / (max - min)) *
              size.width;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, y + 2),
        Paint()
          ..color = const Color(0xFF8AA0B1)
          ..strokeWidth = 1,
      );

      final painter = TextPainter(
        text: TextSpan(
          text: '$tick',
          style: const TextStyle(
            color: kMuted,
            fontSize: 8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          x - painter.width / 2,
          16,
        ),
      );
    }

    final currentX =
        ((velocity - min) / (max - min)) *
            size.width;

    canvas.drawLine(
      Offset(currentX, 0),
      Offset(currentX, y + 2),
      Paint()
        ..color = kYellow
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(
    VeloRulerPainter oldDelegate,
  ) {
    return oldDelegate.velocity != velocity;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PITCH NAME CELL
// ═══════════════════════════════════════════════════════════════════════════════

class PitchNameCell extends StatelessWidget {
  final String name;
  final bool active;
  final ValueChanged<String> onSave;

  const PitchNameCell({
    super.key,
    required this.name,
    required this.active,
    required this.onSave,
  });

  void _edit(BuildContext context) {
    final controller = TextEditingController(
      text: active ? name : '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kCard,
          title: const Text(
            'Enter Pitch Type',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
            ),
            cursorColor: kYellow,
            decoration: const InputDecoration(
              hintText: 'Pitch name',
              hintStyle: TextStyle(
                color: kMuted,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF36536C),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: kYellow,
                ),
              ),
            ),
            onSubmitted: (value) {
              onSave(value);
              Navigator.pop(dialogContext);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: kMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: kYellow,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _edit(context),
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Text(
                active ? name : 'Enter pitch',
                style: TextStyle(
                  color: active
                      ? kYellow
                      : kMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.edit_outlined,
              color: kMuted,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NUMBER CELL
// ═══════════════════════════════════════════════════════════════════════════════

class NumberCell extends StatelessWidget {
  final double? value;
  final bool active;
  final ValueChanged<double?> onSave;

  const NumberCell({
    super.key,
    required this.value,
    required this.active,
    required this.onSave,
  });

  String _format(double value) {
    if (value > 0) {
      return '+${value.round()}';
    }

    return '${value.round()}';
  }

  void _edit(BuildContext context) {
    final controller = TextEditingController(
      text: value == null
          ? ''
          : value!.round().toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kCard,
          title: const Text(
            'Enter Value',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^-?\d*\.?\d*'),
              ),
            ],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            cursorColor: kYellow,
            decoration: const InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF36536C),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: kYellow,
                ),
              ),
            ),
            onSubmitted: (value) {
              onSave(
                double.tryParse(value),
              );

              Navigator.pop(dialogContext);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: kMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                onSave(
                  double.tryParse(
                    controller.text,
                  ),
                );

                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: kYellow,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return const SizedBox(
        height: 45,
        child: Center(
          child: Text(
            '—',
            style: TextStyle(
              color: kMuted,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _edit(context),
      child: SizedBox(
        height: 45,
        child: Center(
          child: Text(
            value == null
                ? '—'
                : _format(value!),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PITCH RECOMMENDATION ENGINE
// ═══════════════════════════════════════════════════════════════════════════════

class RecommendationEngine {
  static List<Recommendation> generate({
    required List<PitchMovement> pitches,
    required int balls,
    required int strikes,
    required int pitchCount,
    required String? timing,
    required String? lastResult,
    required Offset? pitchLocation,
    required String pitcherHand,
    required String batterSide,
  }) {
    if (pitches.isEmpty) {
      return [];
    }

    final locations = [
      'Up & In',
      'Up Middle',
      'Up & Away',
      'Middle In',
      'Middle Middle',
      'Middle Away',
      'Down & In',
      'Down Middle',
      'Down & Away',
    ];

    final List<Recommendation> results = [];

    for (int i = 0; i < pitches.length; i++) {
      final pitch = pitches[i];

      // ──────────────────────────────────────────────────────────────────────
      // BASE SCORE
      // ──────────────────────────────────────────────────────────────────────

      double score = 65;

      // Count-based logic
      if (strikes == 0 && balls >= 2) {
        score += 7;
      }

      if (strikes == 2) {
        score += 8;
      }

      if (balls == 3) {
        score += 6;
      }

      if (balls > strikes) {
        score += 3;
      }

      // Timing logic
      if (timing == 'Early') {
        // Favor off-speed/change-of-speed pitches.
        if (_isOffspeed(pitch.name)) {
          score += 13;
        } else {
          score += 3;
        }
      }

      if (timing == 'Late') {
        // Favor velocity.
        if (_isFastball(pitch.name)) {
          score += 12;
        } else {
          score += 3;
        }
      }

      if (timing == 'On Time') {
        // Movement pitches become slightly more attractive.
        if (_isBreaking(pitch.name)) {
          score += 8;
        }
      }

      // Last-result logic
      if (lastResult == 'Swinging Strike') {
        score += 6;
      }

      if (lastResult == 'Called Strike') {
        score += 4;
      }

      if (lastResult == 'Ball') {
        score -= 2;
      }

      if (lastResult == 'In Play') {
        score += 2;
      }

      // Encourage pitch diversity.
      score += math.min(i * 2, 8);

      // Slightly favor pitches with complete movement data.
      if (pitch.velo != null &&
          pitch.vert != null &&
          pitch.horz != null) {
        score += 5;
      }

      // Keep the value in a sensible range.
      score = score.clamp(45, 98);

      // Determine location.
      final location = _chooseLocation(
        index: i,
        balls: balls,
        strikes: strikes,
        timing: timing,
        pitch: pitch,
        pitcherHand: pitcherHand,
        batterSide: batterSide,
      );

      // Chase vs strike.
      final chase = _isChaseLocation(
        location,
        balls,
        strikes,
      );

      results.add(
        Recommendation(
          pitch: pitch.name,
          location: location,
          score: score,
          chase: chase,
        ),
      );
    }

    results.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    return results.take(5).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCATION GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  static String _chooseLocation({
    required int index,
    required int balls,
    required int strikes,
    required String? timing,
    required PitchMovement pitch,
    required String pitcherHand,
    required String batterSide,
  }) {
    final inside =
        batterSide == 'Righty'
            ? 'In'
            : 'Away';

    final outside =
        batterSide == 'Righty'
            ? 'Away'
            : 'In';

    // Two-strike count:
    if (strikes == 2) {
      final options = [
        'Down & Away',
        'Down & In',
        'Up & Away',
        'Down Middle',
      ];

      return options[
        index % options.length
      ];
    }

    // Three-ball count:
    if (balls == 3) {
      return 'Middle $outside';
    }

    // Early timing:
    if (timing == 'Early') {
      return index.isEven
          ? 'Up & Away'
          : 'Middle $outside';
    }

    // Late timing:
    if (timing == 'Late') {
      return index.isEven
          ? 'Up & $inside'
          : 'Down & $inside';
    }

    final options = [
      'Down & $outside',
      'Up & $inside',
      'Middle $outside',
      'Down Middle',
      'Up Middle',
    ];

    return options[
      index % options.length
    ];
  }

  static bool _isChaseLocation(
    String location,
    int balls,
    int strikes,
  ) {
    // With two strikes, chase locations make more sense.
    if (strikes == 2) {
      return location.contains('Down') ||
          location.contains('Up');
    }

    // Avoid chase recommendations on 3-ball counts.
    if (balls == 3) {
      return false;
    }

    return location.contains('Away') ||
        location.contains('Down');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PITCH TYPE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static bool _isFastball(String name) {
    final n = name.toLowerCase();

    return n.contains('fast') ||
        n.contains('4 seam') ||
        n.contains('four seam') ||
        n.contains('2 seam') ||
        n.contains('two seam') ||
        n.contains('sinker') ||
        n.contains('cutter');
  }

  static bool _isBreaking(String name) {
    final n = name.toLowerCase();

    return n.contains('slider') ||
        n.contains('sweeper') ||
        n.contains('curve') ||
        n.contains('gyro');
  }

  static bool _isOffspeed(String name) {
    final n = name.toLowerCase();

    return n.contains('change') ||
        n.contains('changeup') ||
        n.contains('split') ||
        n.contains('splitter');
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PITCH STATUS MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class _PitchStatus {
  final Color background;
  final Color border;
  final Color foreground;

  const _PitchStatus({
    required this.background,
    required this.border,
    required this.foreground,
  });
}