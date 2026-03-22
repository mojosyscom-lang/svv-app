import 'package:flutter/material.dart';

class DashboardMetricCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String value;

  const DashboardMetricCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth;
        final double cardHeight = constraints.maxHeight;

        // 1. SCALED SIZES (100% Percentage-Based)
        final double iconSize = cardHeight * 0.45; 
        final double titleFontSize = cardHeight * 0.14; 
        final double valueFontSize = cardHeight * 0.22;  
        
        // --- Scaled Aesthetics ---
        final double cardBorderRadius = cardHeight * 0.15; 
        final double iconBorderRadius = cardHeight * 0.10; 
        final double shadowBlur = cardHeight * 0.08;       

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: cardHeight * 0.08, 
            horizontal: cardWidth * 0.06
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(cardBorderRadius), 
            border: Border.all(color: Colors.white, width: cardHeight * 0.015), 
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8DCC4).withOpacity(0.6),
                blurRadius: shadowBlur, 
                offset: Offset(0, cardHeight * 0.05), 
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: shadowBlur * 0.6, 
                offset: Offset(0, cardHeight * 0.02), 
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end, 
            children: [
              // --- 1. TOP ROW ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  // TOP-LEFT ICON
                  Container(
                    padding: EdgeInsets.all(cardHeight * 0.025),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF0EC),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.05),
                          blurRadius: cardHeight * 0.02, 
                          spreadRadius: cardHeight * 0.01, 
                        )
                      ],
                    ),
                    child: Image.asset(
                      imagePath, 
                      width: iconSize,  
                      height: iconSize, 
                      fit: BoxFit.contain, 
                    ),
                  ),
                  
                  SizedBox(width: cardWidth * 0.03), 
                  
                  // TOP-RIGHT TITLE (Now with independent padding!)
                  Expanded(
                    child: Padding(
                      // Nudge the title down by 2% of the card's height. 
                      // Increase this number if it needs to go lower!
                      padding: EdgeInsets.only(top: cardHeight * 0.05), 
                      child: Text(
                        title,
                        textAlign: TextAlign.right, 
                        maxLines: 3, 
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF8C7A6B),
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                          height: 1.1, 
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // --- 2. THE SPRING ---
              const Spacer(),

              // --- 3. BOTTOM-RIGHT AMOUNT ---
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: const Color(0xFF8C7A6B), 
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}