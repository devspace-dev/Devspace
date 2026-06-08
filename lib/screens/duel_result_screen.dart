import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../widgets/user_avatar.dart';

class DuelResultScreen extends StatefulWidget {
  final UserModel me;
  final UserModel opponent;
  final int myScore;
  final int opponentScore;
  final String mode;
  final int myQuestionsAnswered;
  final int opponentQuestionsAnswered;
  final double myAccuracy;
  final double opponentAccuracy;

  const DuelResultScreen({
    super.key,
    required this.me,
    required this.opponent,
    required this.myScore,
    required this.opponentScore,
    required this.mode,
    required this.myQuestionsAnswered,
    required this.opponentQuestionsAnswered,
    required this.myAccuracy,
    required this.opponentAccuracy,
  });

  @override
  State<DuelResultScreen> createState() => _DuelResultScreenState();
}

class _DuelResultScreenState extends State<DuelResultScreen> {
  bool _isMatchDetails = true;

  String get _myChangeStr {
    final bool iWon = widget.myScore >= widget.opponentScore;
    int myBase = iWon ? 15 : -5;
    int myAccBonus = widget.myAccuracy > 80 ? 10 : 0;
    int mySpeedPen = iWon ? 0 : -5;
    int myNet = myBase + myAccBonus + mySpeedPen;
    return myNet >= 0 ? "+$myNet" : "$myNet";
  }

  String get _oppChangeStr {
    final bool iWon = widget.myScore >= widget.opponentScore;
    int oppBase = !iWon ? 15 : -5;
    int oppAccBonus = widget.opponentAccuracy > 80 ? 10 : 0;
    int oppSpeedPen = !iWon ? 0 : -5;
    int oppNet = oppBase + oppAccBonus + oppSpeedPen;
    return oppNet >= 0 ? "+$oppNet" : "$oppNet";
  }

  @override
  Widget build(BuildContext context) {
    final bool iWon = widget.myScore >= widget.opponentScore;
    
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  // Determine slide direction based on which tab is active. 
                  // If we need true directional slide, we can check child.key.
                  final inMatch = child.key == const ValueKey('MatchDetails');
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(inMatch ? -0.05 : 0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _isMatchDetails 
                    ? KeyedSubtree(key: const ValueKey('MatchDetails'), child: _buildMatchDetails(iWon))
                    : KeyedSubtree(key: const ValueKey('DetailedInsights'), child: _buildDetailedInsights()),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.home_filled, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabButton("MATCH DETAILS", _isMatchDetails),
                const SizedBox(width: 8),
                _buildTabButton("DETAILED INSIGHTS", !_isMatchDetails),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMatchDetails = title == "MATCH DETAILS";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: isSelected ? Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)) : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isSelected ? Colors.greenAccent : Colors.white38,
          ),
        ),
      ),
    );
  }

  Widget _buildMatchDetails(bool iWon) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildScoreText(widget.myScore.toString(), iWon),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "-",
                  style: TextStyle(fontSize: 40, color: Colors.white54, fontWeight: FontWeight.bold),
                ),
              ),
              _buildScoreText(widget.opponentScore.toString(), !iWon),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPlayerInfo(widget.me, _myChangeStr, iWon, isLeft: true),
              const Icon(Icons.psychology, color: Colors.white38, size: 32),
              _buildPlayerInfo(widget.opponent, _oppChangeStr, !iWon, isLeft: false),
            ],
          ),
          const SizedBox(height: 48),
          
          _buildGraphSection(iWon),
          
          const SizedBox(height: 40),
          
          _buildStatRow("ACCURACY", "${widget.myAccuracy.toStringAsFixed(2)}%", "${widget.opponentAccuracy.toStringAsFixed(2)}%"),
          const SizedBox(height: 16),
          _buildStatRow("TOTAL BOARDS\nATTEMPTED", "${widget.myQuestionsAnswered}", "${widget.opponentQuestionsAnswered}"),
        ],
      ),
    );
  }

  Widget _buildScoreText(String score, bool isWinner) {
    return Stack(
      children: [
        if (isWinner)
          Positioned(
            left: 2,
            top: 2,
            child: Text(
              score,
              style: GoogleFonts.oswald(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
          ),
        Text(
          score,
          style: GoogleFonts.oswald(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: isWinner ? Colors.white : Colors.white24,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerInfo(UserModel user, String auraChange, bool isWinner, {required bool isLeft}) {
    final auraChangeColor = isWinner ? Colors.greenAccent : Colors.redAccent;
    final arrowIcon = isWinner ? Icons.arrow_drop_up : Icons.arrow_drop_down;
    
    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLeft) ...[
              UserAvatar(user: user, size: 24),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                user.name,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (!isLeft) ...[
              const SizedBox(width: 8),
              UserAvatar(user: user, size: 24),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "(${user.aura})",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
            Icon(arrowIcon, color: auraChangeColor, size: 20),
            Text(
              auraChange.replaceAll(RegExp(r'[+-]'), ''),
              style: GoogleFonts.plusJakartaSans(
                color: auraChangeColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGraphSection(bool iWon) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) => const Divider(color: Colors.white12, height: 1)),
          ),
          
          CustomPaint(
            size: const Size(double.infinity, 150),
            painter: _StepChartPainter(
              myColor: iWon ? Colors.greenAccent : Colors.grey,
              opponentColor: !iWon ? Colors.greenAccent : Colors.grey,
            ),
          ),
          
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, color: iWon ? Colors.greenAccent : Colors.grey, size: 12),
                  const SizedBox(width: 8),
                  Text("${widget.myScore} pts", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  const Text("00:34:00", style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 12),
                  Text("${widget.opponentScore} pts", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Icon(Icons.circle, color: !iWon ? Colors.greenAccent : Colors.grey, size: 12),
                ],
              ),
            ),
          ),
          const Positioned(
            top: 40,
            bottom: 0,
            child: VerticalDivider(color: Colors.white24, width: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String leftValue, String rightValue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              leftValue,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rightValue,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInsights() {
    final myCorrect = widget.myScore ~/ 15;
    final oppCorrect = widget.opponentScore ~/ 15;
    final mySpeed = widget.myQuestionsAnswered > 0 ? (60.0 / widget.myQuestionsAnswered).toStringAsFixed(1) : "0.0";
    final oppSpeed = widget.opponentQuestionsAnswered > 0 ? (60.0 / widget.opponentQuestionsAnswered).toStringAsFixed(1) : "0.0";
    final mySpeedVal = double.tryParse(mySpeed) ?? 0.0;
    final oppSpeedVal = double.tryParse(oppSpeed) ?? 0.0;
    // Faster is better for speed, so lower value wins, unless it's 0 (meaning no questions answered).
    final isMySpeedWin = (mySpeedVal > 0 && oppSpeedVal > 0) ? mySpeedVal <= oppSpeedVal : mySpeedVal > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PERFORMANCE METRICS",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            title: "Response Speed",
            subtitle: "Average time per question",
            myValue: "${mySpeed}s",
            oppValue: "${oppSpeed}s",
            isMyWin: isMySpeedWin,
            icon: Icons.bolt,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            title: "Questions Correct",
            subtitle: "Total accurate answers",
            myValue: "$myCorrect",
            oppValue: "$oppCorrect",
            isMyWin: myCorrect >= oppCorrect,
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            title: "Longest Streak",
            subtitle: "Consecutive correct answers",
            myValue: "${myCorrect > 2 ? myCorrect - 1 : myCorrect}", 
            oppValue: "${oppCorrect > 2 ? oppCorrect - 2 : oppCorrect}",
            isMyWin: (myCorrect > 2 ? myCorrect - 1 : myCorrect) >= (oppCorrect > 2 ? oppCorrect - 2 : oppCorrect),
            icon: Icons.local_fire_department,
          ),
          const SizedBox(height: 32),
          Text(
            "AURA BREAKDOWN",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildAuraBreakdown(),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String subtitle,
    required String myValue,
    required String oppValue,
    required bool isMyWin,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isMyWin ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isMyWin ? Colors.greenAccent : Colors.redAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                myValue,
                style: GoogleFonts.plusJakartaSans(
                  color: isMyWin ? Colors.greenAccent : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                "vs $oppValue",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuraBreakdown() {
    final bool iWon = widget.myScore >= widget.opponentScore;
    
    int baseAura = iWon ? 15 : -5;
    int accuracyBonus = widget.myAccuracy > 80 ? 10 : 0;
    int speedPenalty = iWon ? 0 : -5;
    int netAura = baseAura + accuracyBonus + speedPenalty;
    
    final myChange = netAura >= 0 ? "+$netAura" : "$netAura";
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Match Result", style: TextStyle(color: Colors.white70)),
              Text(iWon ? "+15 Aura" : "-5 Aura", style: TextStyle(color: iWon ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Accuracy Bonus", style: TextStyle(color: Colors.white70)),
              Text(widget.myAccuracy > 80 ? "+10 Aura" : "+0 Aura", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Speed Penalty", style: TextStyle(color: Colors.white70)),
              Text(iWon ? "+0 Aura" : "-5 Aura", style: TextStyle(color: iWon ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white12),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Net Aura Change", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(myChange, style: TextStyle(color: iWon ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white12),
                ),
              ),
              child: Text(
                "REMATCH",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.greenAccent, width: 2),
                ),
              ),
              child: Text(
                "NEW GAME",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepChartPainter extends CustomPainter {
  final Color myColor;
  final Color opponentColor;

  _StepChartPainter({required this.myColor, required this.opponentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final myPaint = Paint()
      ..color = myColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final opponentPaint = Paint()
      ..color = opponentColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final myPath = Path();
    final opponentPath = Path();

    int steps = 10;
    double stepWidth = size.width / steps;
    
    double myY = size.height - 10;
    double oppY = size.height - 5;

    myPath.moveTo(0, myY);
    opponentPath.moveTo(0, oppY);

    for (int i = 1; i <= steps; i++) {
      double x = i * stepWidth;
      
      myPath.lineTo(x - stepWidth/2, myY);
      opponentPath.lineTo(x - stepWidth/2, oppY);
      
      myY -= (size.height / steps) * 0.8; 
      oppY -= (size.height / steps) * 0.6; 

      myPath.lineTo(x - stepWidth/2, myY);
      opponentPath.lineTo(x - stepWidth/2, oppY);

      myPath.lineTo(x, myY);
      opponentPath.lineTo(x, oppY);
    }

    canvas.drawPath(opponentPath, opponentPaint);
    canvas.drawPath(myPath, myPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
