import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/responsive_helper.dart';
import '../../services/database_service.dart';
import '../../utils/home_utils.dart';
import '../../pages/account_page.dart';
import '../withdrawal_dialog.dart';

class ProfileHeader extends StatelessWidget {
  final User? currentUser;
  final DatabaseService databaseService;

  const ProfileHeader({
    super.key,
    required this.currentUser,
    required this.databaseService,
  });

  @override
  Widget build(BuildContext context) {
    final iconScale = ResponsiveHelper.getIconScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final fontScale = ResponsiveHelper.getFontScale(context);
    
    final userName = currentUser?.displayName ?? 
                    currentUser?.email?.split('@')[0] ?? 
                    'Pengguna';
    
    final greeting = getGreeting();
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24 * paddingScale),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section with Photo
            Row(
              children: [
                // Profile Photo
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AccountPage()),
                    );
                  },
                  child: Container(
                    width: 60 * iconScale,
                    height: 60 * iconScale,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: currentUser?.photoURL != null
                        ? ClipOval(
                            child: Image.network(
                              currentUser!.photoURL!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 30 * iconScale,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 30 * iconScale,
                          ),
                  ),
                ),
                SizedBox(width: 16 * paddingScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$greeting, $userName! 👋",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: (Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24) * fontScale,
                        ),
                      ),
                      SizedBox(height: 4 * paddingScale),
                      Text(
                        currentUser?.email ?? 'Pengguna',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8 * iconScale),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16 * iconScale,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24 * paddingScale),
            
            // Store Balance Summary
            StreamBuilder<double>(
              stream: databaseService.getStoreBalanceStream(),
              builder: (context, balanceSnapshot) {
                return StreamBuilder<double>(
                  stream: databaseService.getTodayRevenueStream(),
                  builder: (context, todaySnapshot) {
                    return StreamBuilder<double>(
                      stream: databaseService.getYesterdayRevenueStream(),
                      builder: (context, yesterdaySnapshot) {
                        final storeBalance = balanceSnapshot.data ?? 0.0;
                        final todayRevenue = todaySnapshot.data ?? 0.0;
                        final yesterdayRevenue = yesterdaySnapshot.data ?? 0.0;
                        
                        String growthPercent = '0.0';
                        bool isPositiveGrowth = true;
                        
                        if (yesterdayRevenue > 0) {
                          final growth = ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
                          growthPercent = growth.toStringAsFixed(1);
                          isPositiveGrowth = growth >= 0;
                        } else if (todayRevenue > 0) {
                          growthPercent = '100.0';
                          isPositiveGrowth = true;
                        }
                        
                        return Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(20 * paddingScale),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Saldo Toko",
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w500,
                                            fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
                                          ),
                                        ),
                                        SizedBox(height: 8 * paddingScale),
                                        Text(
                                          "Rp ${formatCurrency(storeBalance.toInt())}",
                                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: (Theme.of(context).textTheme.headlineMedium?.fontSize ?? 28) * fontScale,
                                          ),
                                        ),
                                        SizedBox(height: 8 * paddingScale),
                                        // Mini Growth Indicator
                                        if (yesterdayRevenue > 0 || todayRevenue > 0)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12 * paddingScale,
                                              vertical: 6 * paddingScale,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isPositiveGrowth 
                                                  ? Colors.green.withOpacity(0.25)
                                                  : Colors.red.withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isPositiveGrowth 
                                                      ? Icons.trending_up_rounded
                                                      : Icons.trending_down_rounded,
                                                  color: Colors.white,
                                                  size: 16 * iconScale,
                                                ),
                                                SizedBox(width: 6 * paddingScale),
                                                Text(
                                                  "${isPositiveGrowth ? '+' : ''}$growthPercent% dari kemarin",
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * fontScale,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(16 * iconScale),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      Icons.show_chart_rounded,
                                      color: Colors.white,
                                      size: 40 * iconScale,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12 * paddingScale),
                            // Pencairan Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  showDialog(
                                    context: context,
                                    builder: (context) => WithdrawalDialog(
                                      currentBalance: storeBalance,
                                      databaseService: databaseService,
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 20 * iconScale,
                                ),
                                label: Text(
                                  'Pencairan',
                                  style: TextStyle(
                                    fontSize: 14 * fontScale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF6366F1),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20 * paddingScale,
                                    vertical: 14 * paddingScale,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


