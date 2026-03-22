import 'dart:ui';
import 'package:flutter/material.dart';

class DashboardHeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String amount;
  final String changeText;
  final List<Color> gradientColors;

  const DashboardHeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.amount,
    required this.changeText,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth;
        final double cardHeight = constraints.maxHeight;

        String? bgImagePath;

        Offset changeTextOffset = const Offset(0, 0); 

        // --- 1. DEFAULT STYLING & PERCENTAGE ALIGNMENTS ---
        // FractionalOffset(x, y): 0.0 is 0%, 1.0 is 100%
        FractionalOffset titleAlignment = const FractionalOffset(0.0, 0.0); // 0% (Left)
        FractionalOffset amountAlignment = const FractionalOffset(0.0, 0.0); // 0% (Left)
        
        Offset titleOffset = const Offset(0, 0);
        Offset amountOffset = const Offset(0, 0);

        Color titleColor = const Color(0xFFDCB771); 
        Color amountColor = const Color(0xFFDCB771);
        
        List<Shadow> titleShadows = [
          Shadow(
            color: Colors.black.withOpacity(0.7), 
            blurRadius: 3, 
            offset: const Offset(1, 2), 
          ),
        ];
        List<Shadow> amountShadows = [
          Shadow(
            color: Colors.black.withOpacity(0.7), 
            blurRadius: 3, 
            offset: const Offset(1, 2), 
          ),
        ];

        // --- 2. CARD-SPECIFIC LOGIC ---
        if (title == 'Account Balance') {
          bgImagePath = 'assets/images/account-balance.png';
          changeTextOffset = Offset(-cardWidth * 0.05, cardHeight * 0.03); 
          
          titleOffset = Offset(cardWidth * 0.03, -cardHeight * 0.05); 
          amountOffset = Offset(cardWidth * 0.03, -cardHeight * 0.04); 
          
          titleAlignment = const FractionalOffset(0.0, 0.0); // 0% across (Left)
          amountAlignment = const FractionalOffset(0.0, 0.0); // 0% across (Left)

        } else if (title == 'Total Income') {
          bgImagePath = 'assets/images/total-income.png';
          changeTextOffset = Offset(-cardWidth * 0.05, cardHeight * 0.03); 

          // OVERRIDES FOR TOTAL INCOME
          titleOffset = Offset(-cardWidth * 0.04, -cardHeight * 0.05); 
          amountOffset = Offset(-cardWidth * 0.04, -cardHeight * 0.04); 
          
          // Using percentages: 1.0 means 100% to the right side of the container
          titleAlignment = const FractionalOffset(0.15, 0.0); // 100% across (Right)
          amountAlignment = const FractionalOffset(0.1, 0.0); // 100% across (Right)
          
          titleColor = const Color(0xFFD6AD70); 
          amountColor = const Color(0xFFD6AD70); 
          
          titleShadows = [
            Shadow(
              color: Colors.black.withOpacity(0.5), 
              blurRadius: 8, 
              offset: const Offset(0, 0), 
            ),
          ];
          amountShadows = [
            Shadow(
              color: const Color(0xFF967758).withOpacity(0.6), 
              blurRadius: 10, 
              offset: const Offset(0, 0), 
            ),
            Shadow(
              color: Colors.black.withOpacity(0.8), 
              blurRadius: 4, 
              offset: const Offset(2, 2), 
            ),
          ];

        } else if (title == 'Salary') {
          bgImagePath = 'assets/images/salary.png';
          changeTextOffset = Offset(-cardWidth * 0.05, cardHeight * 0.03); 
          
          titleOffset = Offset(cardWidth * 0.05, -cardHeight * 0.05); 
          amountOffset = Offset(cardWidth * 0.05, -cardHeight * 0.04); 
          
          // Example of center alignment using 50% (0.5)
          titleAlignment = const FractionalOffset(-0.035, 0.0); // 50% across (Center)
          amountAlignment = const FractionalOffset(-0.03, 0.0); // 50% across (Center)

          titleColor = const Color(0xFFC98E5B); 
          amountColor = const Color(0xFFC98E5B); 

          titleShadows = [
            Shadow(
              color: Colors.black.withOpacity(0.7), 
              blurRadius: 5, 
              offset: const Offset(1, 0), 
            ),
          ];
          amountShadows = [
            Shadow(
              color: const Color(0xFF967758).withOpacity(0.6), 
              blurRadius: 10, 
              offset: const Offset(0, 0), 
            ),
            Shadow(
              color: Colors.black.withOpacity(0.8), 
              blurRadius: 4, 
              offset: const Offset(2, 2), 
            ),
          ];
        }

        bool hasBackgroundImage = bgImagePath != null;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35), 
                blurRadius: 25, 
                offset: Offset(0, cardHeight * 0.09), 
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasBackgroundImage)
                  Image.asset(
                    bgImagePath!,
                    fit: BoxFit.fill,
                  ),

                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: hasBackgroundImage ? 0.0 : 6.0,
                    sigmaY: hasBackgroundImage ? 0.0 : 6.0,
                  ),
                  child: Container(
                    // --- THE FIX: Split the padding! ---
                    padding: EdgeInsets.symmetric(
                      horizontal: cardWidth * 0.06, // Left/Right uses width
                      vertical: cardHeight * 0.06,  // Top/Bottom uses height
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          hasBackgroundImage ? Colors.transparent : Colors.white.withOpacity(0.15),
                          hasBackgroundImage ? Colors.transparent : Colors.white.withOpacity(0.02),
                        ],
                      ),
                      border: Border.all(
                        color: hasBackgroundImage ? Colors.transparent : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),

                    // --- 3. APPLYING THE PERCENTAGES TO THE WIDGETS ---
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Forces full width so alignment works
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(cardWidth * 0.03),
                              decoration: BoxDecoration(
                                color: hasBackgroundImage ? Colors.transparent : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: hasBackgroundImage ? Colors.transparent : Colors.white.withOpacity(0.3)
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: hasBackgroundImage ? Colors.transparent : Colors.amberAccent,
                                size: cardWidth * 0.07 
                              ),
                            ),

                            Transform.translate(
                              offset: changeTextOffset,
                              child: Text(
                                changeText,
                                style: TextStyle(
                                  color: const Color(0xFFFFD166),
                                  fontWeight: FontWeight.bold,
                                  fontSize: cardHeight * 0.065,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.6),
                                      blurRadius: 4,
                                      offset: const Offset(1, 1),
                                    ),
                                  ]
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // TITLE WIDGET
                            Transform.translate(
                              offset: titleOffset, // Nudge by percentage of card size
                              child: Align(
                                alignment: titleAlignment, // Main alignment by percentage (0.0 to 1.0)
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      color: titleColor, 
                                      fontSize: cardHeight * 0.15, 
                                      fontWeight: FontWeight.w700, 
                                      letterSpacing: 0.5,
                                      height: 1.2, 
                                      shadows: titleShadows, 
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // AMOUNT WIDGET
                            Transform.translate(
                              offset: amountOffset, // Nudge by percentage of card size
                              child: Align(
                                alignment: amountAlignment, // Main alignment by percentage (0.0 to 1.0)
                                child: Text(
                                  amount,
                                  style: TextStyle(
                                    color: amountColor, 
                                    fontSize: cardHeight * 0.18, 
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    height: 1.0,
                                    shadows: amountShadows, 
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}