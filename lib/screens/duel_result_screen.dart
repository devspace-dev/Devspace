import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  final List<int>? myScoreTimeline;
  final List<int>? opponentScoreTimeline;
  final UserModel? teammate;
  final UserModel? opponentTeammate;

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
    this.myScoreTimeline,
    this.opponentScoreTimeline,
    this.teammate,
    this.opponentTeammate,
  });

  @override
  State<DuelResultScreen> createState() => _DuelResultScreenState();
}

class _DuelResultScreenState extends State<DuelResultScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

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
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool iWon = widget.myScore >= widget.opponentScore;
    final themeColor = iWon ? const Color(0xFF00FFCC) : const Color(0xFFFF416C);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColor.withValues(alpha: 0.08),
              const Color(0xFF0F0F12),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(iWon, themeColor),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildOverviewCard(iWon, themeColor),
                    _buildDetailedAnalytics(iWon, themeColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool iWon, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              child: const Icon(Icons.home_filled, color: Colors.white, size: 22),
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabButton("SUMMARY", _currentPage == 0, themeColor, () => _navigateToPage(0)),
                  const SizedBox(width: 8),
                  _buildTabButton("ANALYSIS", _currentPage == 1, themeColor, () => _navigateToPage(1)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48), // Balances the home button's width on the left to keep center buttons centered
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected, Color themeColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? themeColor.withValues(alpha: 0.5) : Colors.white12,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isSelected ? themeColor : Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(bool iWon, Color themeColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 10),
                  // Title / Status
                  Column(
                    children: [
                      Text(
                        iWon ? "VICTORY" : "DEFEAT",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: themeColor,
                          shadows: [
                            Shadow(color: themeColor.withValues(alpha: 0.5), blurRadius: 15),
                          ],
                        ),
                      ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 8),
                      Text(
                        widget.mode.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white54,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  // High-fidelity Score Banner
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildBigScore(widget.myScore.toString(), iWon, themeColor),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                "vs",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                            _buildBigScore(widget.opponentScore.toString(), !iWon, Colors.white24),
                          ],
                        ),
                        if (widget.teammate != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            "Each player got ${widget.myScore ~/ 2} pts",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white38,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Player comparisons card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left Player: Me
                            Expanded(child: _buildCompactPlayer(widget.me, widget.teammate, _myChangeStr, iWon, isLeft: true)),
                            const SizedBox(width: 8),
                            // Divider
                            Container(
                              height: 64,
                              width: 1,
                              color: Colors.white12,
                            ),
                            const SizedBox(width: 8),
                            // Right Player: Opponent
                            Expanded(child: _buildCompactPlayer(widget.opponent, widget.opponentTeammate, _oppChangeStr, !iWon, isLeft: false)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(color: Colors.white10, height: 1),
                        ),
                        // Quick Stats / Rewards Overview
                        Row(
                          children: [
                            Expanded(
                              child: _buildRewardItem(
                                title: "RATING CHANGE",
                                value: _myChangeStr,
                                subtext: "Aura Points",
                                isPositive: iWon,
                                themeColor: themeColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRewardItem(
                                title: "TOTAL ACCURACY",
                                value: "${widget.myAccuracy.toStringAsFixed(0)}%",
                                subtext: "${widget.myQuestionsAnswered} answered",
                                isPositive: widget.myAccuracy >= 80,
                                themeColor: const Color(0xFF00FFCC),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Actions
                  Column(
                    children: [
                      _buildActionButtons(),
                      const SizedBox(height: 24),
                      // Swipe indicator
                      GestureDetector(
                        onTap: () => _navigateToPage(1),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.keyboard_double_arrow_up_rounded, color: Colors.white38, size: 24)
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .moveY(begin: 0, end: -6, duration: 800.ms),
                            const SizedBox(height: 4),
                            Text(
                              "SWIPE UP FOR DETAILED ANALYSIS",
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white30,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailedAnalytics(bool iWon, Color themeColor) {
    // Math formulas for detailed stats
    final myCorrect = widget.myScore ~/ 15;
    final oppCorrect = widget.opponentScore ~/ 15;
    final mySpeed = widget.myQuestionsAnswered > 0 ? (60.0 / widget.myQuestionsAnswered).toStringAsFixed(1) : "0.0";
    final oppSpeed = widget.opponentQuestionsAnswered > 0 ? (60.0 / widget.opponentQuestionsAnswered).toStringAsFixed(1) : "0.0";
    final mySpeedVal = double.tryParse(mySpeed) ?? 0.0;
    final oppSpeedVal = double.tryParse(oppSpeed) ?? 0.0;
    final isMySpeedWin = (mySpeedVal > 0 && oppSpeedVal > 0) ? mySpeedVal <= oppSpeedVal : mySpeedVal > 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle indicator (Swipe down)
          Center(
            child: GestureDetector(
              onTap: () => _navigateToPage(0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.keyboard_double_arrow_down_rounded, color: Colors.white24, size: 20)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: 0, end: 4, duration: 800.ms),
                  const SizedBox(height: 2),
                  Text(
                    "SWIPE DOWN FOR SUMMARY",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white30,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Graph Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SCORE TRAJECTORY",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              Row(
                children: [
                  _buildLegendIndicator("You", const Color(0xFF00FFCC)),
                  const SizedBox(width: 12),
                  _buildLegendIndicator(widget.opponent.name, const Color(0xFFFF416C)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic Graph Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _DynamicMatchGraphPainter(
                      myScoreTimeline: widget.myScoreTimeline ?? [0, widget.myScore],
                      opponentScoreTimeline: widget.opponentScoreTimeline ?? [0, widget.opponentScore],
                      myColor: const Color(0xFF00FFCC),
                      opponentColor: const Color(0xFFFF416C),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("START", style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text("TIME ELAPSED", style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text("END", style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Performance Metrics List
          Text(
            "MATCH INSIGHTS",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          _buildInsightRow(
            title: "Response Speed",
            subtitle: "Average time per question",
            myValue: "${mySpeed}s",
            oppValue: "${oppSpeed}s",
            isMyWin: isMySpeedWin,
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            title: "Questions Correct",
            subtitle: "Total accurate answers",
            myValue: "$myCorrect",
            oppValue: "$oppCorrect",
            isMyWin: myCorrect >= oppCorrect,
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            title: "Accuracy",
            subtitle: "Answers precision rate",
            myValue: "${widget.myAccuracy.toStringAsFixed(0)}%",
            oppValue: "${widget.opponentAccuracy.toStringAsFixed(0)}%",
            isMyWin: widget.myAccuracy >= widget.opponentAccuracy,
            icon: Icons.track_changes_rounded,
          ),

          const SizedBox(height: 28),

          // Aura Breakdown card
          Text(
            "AURA ADJUSTMENT DETAILS",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildAuraBreakdownCard(iWon),

          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 24),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildBigScore(String score, bool isLeader, Color color) {
    return Text(
      score,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: isLeader ? Colors.white : Colors.white24,
      ),
    );
  }

  Widget _buildCompactPlayer(UserModel user, UserModel? teammate, String auraChange, bool isWinner, {required bool isLeft}) {
    final auraColor = isWinner ? const Color(0xFF00FFCC) : const Color(0xFFFF416C);
    final avatarBorder = isWinner ? const Color(0xFF00FFCC) : Colors.white24;

    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLeft) ...[
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: avatarBorder, width: 1.5),
                ),
                child: UserAvatar(user: user, size: 24),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                user.id == widget.me.id ? "You" : user.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            if (!isLeft) ...[
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: avatarBorder, width: 1.5),
                ),
                child: UserAvatar(user: user, size: 24),
              ),
            ],
          ],
        ),
        if (teammate != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLeft) ...[
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: avatarBorder.withValues(alpha: 0.7), width: 1.2),
                  ),
                  child: UserAvatar(user: teammate, size: 20),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  teammate.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              if (!isLeft) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: avatarBorder.withValues(alpha: 0.7), width: 1.2),
                  ),
                  child: UserAvatar(user: teammate, size: 20),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              teammate != null
                  ? "${(user.aura + teammate.aura) ~/ 2} Avg Aura"
                  : "${user.aura} Aura",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "($auraChange)",
              style: GoogleFonts.plusJakartaSans(
                color: auraColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRewardItem({
    required String title,
    required String value,
    required String subtext,
    required bool isPositive,
    required Color themeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: themeColor,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(String name, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightRow({
    required String title,
    required String subtitle,
    required String myValue,
    required String oppValue,
    required bool isMyWin,
    required IconData icon,
  }) {
    final winColor = const Color(0xFF00FFCC);
    final loseColor = const Color(0xFFFF416C);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isMyWin ? winColor : loseColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isMyWin ? winColor : loseColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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
                  color: isMyWin ? winColor : Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "vs $oppValue",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuraBreakdownCard(bool iWon) {
    int baseAura = iWon ? 15 : -5;
    int accuracyBonus = widget.myAccuracy > 80 ? 10 : 0;
    int speedPenalty = iWon ? 0 : -5;
    int netAura = baseAura + accuracyBonus + speedPenalty;
    final myChange = netAura >= 0 ? "+$netAura" : "$netAura";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildBreakdownRow("Match Outcome", baseAura >= 0 ? "+$baseAura" : "$baseAura", baseAura >= 0),
          const SizedBox(height: 10),
          _buildBreakdownRow("Accuracy Bonus (>80%)", accuracyBonus > 0 ? "+$accuracyBonus" : "+0", accuracyBonus > 0),
          const SizedBox(height: 10),
          _buildBreakdownRow("Speed Defect Penalty", speedPenalty < 0 ? "$speedPenalty" : "+0", speedPenalty >= 0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white10),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Net Aura Earned", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                myChange,
                style: GoogleFonts.plusJakartaSans(
                  color: netAura >= 0 ? const Color(0xFF00FFCC) : const Color(0xFFFF416C),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, bool isPositive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: isPositive ? const Color(0xFF00FFCC) : Colors.white30,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.03),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white10),
              ),
            ),
            child: Text(
              "REMATCH",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FFCC).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF00FFCC),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF00FFCC), width: 1),
              ),
            ),
            child: Text(
              "NEW DUEL",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DynamicMatchGraphPainter extends CustomPainter {
  final List<int> myScoreTimeline;
  final List<int> opponentScoreTimeline;
  final Color myColor;
  final Color opponentColor;

  _DynamicMatchGraphPainter({
    required this.myScoreTimeline,
    required this.opponentScoreTimeline,
    required this.myColor,
    required this.opponentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (myScoreTimeline.isEmpty || opponentScoreTimeline.isEmpty) return;

    // Find the maximum score to set the Y ceiling
    int maxMyScore = myScoreTimeline.reduce((a, b) => a > b ? a : b);
    int maxOppScore = opponentScoreTimeline.reduce((a, b) => a > b ? a : b);
    int maxScore = maxMyScore > maxOppScore ? maxMyScore : maxOppScore;
    if (maxScore == 0) maxScore = 1;

    // Leaving some Y headroom
    double yScale = (size.height - 24) / maxScore;

    int myLength = myScoreTimeline.length;
    int oppLength = opponentScoreTimeline.length;
    double myXStep = size.width / (myLength - 1 > 0 ? myLength - 1 : 1);
    double oppXStep = size.width / (oppLength - 1 > 0 ? oppLength - 1 : 1);

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final myPaint = Paint()
      ..color = myColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final opponentPaint = Paint()
      ..color = opponentColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final myPath = Path();
    final opponentPath = Path();

    // Plot my line (staircase style matching exact answers completed)
    myPath.moveTo(0, size.height - (myScoreTimeline[0] * yScale));
    for (int i = 1; i < myLength; i++) {
      final double x = i * myXStep;
      final double y = size.height - (myScoreTimeline[i] * yScale);
      final double prevY = size.height - (myScoreTimeline[i - 1] * yScale);
      myPath.lineTo(x, prevY);
      myPath.lineTo(x, y);
    }

    // Plot opponent line (staircase style)
    opponentPath.moveTo(0, size.height - (opponentScoreTimeline[0] * yScale));
    for (int i = 1; i < oppLength; i++) {
      final double x = i * oppXStep;
      final double y = size.height - (opponentScoreTimeline[i] * yScale);
      final double prevY = size.height - (opponentScoreTimeline[i - 1] * yScale);
      opponentPath.lineTo(x, prevY);
      opponentPath.lineTo(x, y);
    }

    // Draw lines
    canvas.drawPath(opponentPath, opponentPaint);
    canvas.drawPath(myPath, myPaint);

    // Draw little circles at each score increment
    final dotPaintMy = Paint()
      ..color = myColor
      ..style = PaintingStyle.fill;
    final dotPaintOpp = Paint()
      ..color = opponentColor
      ..style = PaintingStyle.fill;

    for (int i = 1; i < myLength; i++) {
      if (myScoreTimeline[i] > myScoreTimeline[i - 1]) {
        canvas.drawCircle(
          Offset(i * myXStep, size.height - (myScoreTimeline[i] * yScale)),
          4.5,
          dotPaintMy,
        );
      }
    }
    for (int i = 1; i < oppLength; i++) {
      if (opponentScoreTimeline[i] > opponentScoreTimeline[i - 1]) {
        canvas.drawCircle(
          Offset(i * oppXStep, size.height - (opponentScoreTimeline[i] * yScale)),
          4.5,
          dotPaintOpp,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicMatchGraphPainter oldDelegate) {
    return oldDelegate.myScoreTimeline != myScoreTimeline ||
        oldDelegate.opponentScoreTimeline != opponentScoreTimeline;
  }
}
