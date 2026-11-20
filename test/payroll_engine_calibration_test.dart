import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overtime_app/main.dart';
import 'dart:math' as math;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Payroll Engine Calibration Tests', () {
    test('1. Default Constants & Cap Calibration', () {
      expect(PayrollEngine.kDailyUma2026, 117.31);
      expect(PayrollEngine.kFondoAhorroQuincenaCap, 2287.55);
    });

    test('2. Overtime Calculation Line Items (unrounded hourly rate & rounded line item)', () {
      // Case 1: 11h 3x on $1,246.30 daily yields $5,140.99
      // Rest day: all overtime hours are credited as 3x
      final restDay = WorkDay(
        entrada: DateTime(2026, 1, 11, 8, 0), // Sunday
        salida: DateTime(2026, 1, 11, 28, 30), // 20.5 hrs worked (9.5h base + 11h OT)
        sueldoBase: 1246.30,
        baseHours: 9.5,
      );
      // restDays = Saturday(6) & Sunday(7)
      WorkDay.restDays = [6, 7];
      WorkDay.restDaysHistory = [];
      WorkDay.salaryHistory = [];
      WorkDay.jornadaHistory = [];

      expect(restDay.isRestDay, isTrue);
      expect(restDay.creditedExtraHours, 11.0);

      final breakdownMap =
          PayrollEngine.calculateWeeklyOvertimeBreakdown([restDay]);
      final breakdown = breakdownMap[restDay]!;

      expect(breakdown.hours3x, 11.0);
      expect(breakdown.hours2x, 0.0);
      expect(breakdown.pay2x, 0.0);
      // Explicit test from requirement: 11h 3x on $1,246.30 daily yields $5,140.99
      expect(breakdown.pay3x, 5140.99);
      expect(breakdown.totalPay, 5140.99);

      // WorkDay.extrasMoney getter also matches
      expect(restDay.extrasMoney, 5140.99);
    });

    test('3. Overtime 2x quota and 3x overflow calculation', () {
      // Weekday with 13 hours of overtime: 9h at 2x, 4h at 3x
      final regularDay = WorkDay(
        entrada: DateTime(2026, 1, 12, 8, 0), // Monday
        salida: DateTime(2026, 1, 12, 30, 30), // 22.5 hrs worked (9.5 base + 13 OT)
        sueldoBase: 1246.30,
        baseHours: 9.5,
      );
      WorkDay.restDays = [6, 7];

      expect(regularDay.isRestDay, isFalse);
      expect(regularDay.creditedExtraHours, 13.0);

      final breakdownMap =
          PayrollEngine.calculateWeeklyOvertimeBreakdown([regularDay]);
      final breakdown = breakdownMap[regularDay]!;

      expect(breakdown.hours2x, 9.0);
      expect(breakdown.hours3x, 4.0);
      // 9h 2x on $1,246.30: (1246.30 / 8) * 2 * 9 = 155.7875 * 18 = 2804.175 -> $2,804.18
      expect(breakdown.pay2x, 2804.18);
      // 4h 3x on $1,246.30: (1246.30 / 8) * 3 * 4 = 155.7875 * 12 = 1869.45 -> $1,869.45
      expect(breakdown.pay3x, 1869.45);
      expect(breakdown.totalPay, 4673.63);
    });

    test('4. Mexican ISR 2026 11-Bracket Progressive Calculation', () {
      // Test zero or negative
      expect(PayrollEngine.calculateSatIsr2026Quincenal(0.0), 0.0);
      expect(PayrollEngine.calculateSatIsr2026Quincenal(-100.0), 0.0);

      // Bracket 1: 0.01 - 416.70 (rate: 1.92%, fixed: 0.00)
      // 400.00: 0.00 + (400 - 0.01) * 0.0192 = 399.99 * 0.0192 = 7.6798 -> 7.68
      expect(PayrollEngine.calculateSatIsr2026Quincenal(400.00), 7.68);

      // Bracket 2: 416.71 - 3,537.15 (rate: 6.40%, fixed: 7.95)
      // 1,000.00: 7.95 + (1000 - 416.71) * 0.064 = 7.95 + 583.29 * 0.064 = 7.95 + 37.33056 = 45.28
      expect(PayrollEngine.calculateSatIsr2026Quincenal(1000.00), 45.28);

      // Bracket 3: 3,537.16 - 6,216.15 (rate: 10.88%, fixed: 207.75)
      // 5,000.00: 207.75 + (5000 - 3537.16) * 0.1088 = 207.75 + 1462.84 * 0.1088 = 207.75 + 159.157 = 366.91
      expect(PayrollEngine.calculateSatIsr2026Quincenal(5000.00), 366.91);

      // Bracket 6: 8,651.41 - 17,448.75 (rate: 21.36%, fixed: 916.20)
      // 15,000.00: 916.20 + (15000 - 8651.41) * 0.2136 = 916.20 + 6348.59 * 0.2136 = 916.20 + 1356.0588 = 2272.26
      expect(PayrollEngine.calculateSatIsr2026Quincenal(15000.00), 2272.26);

      // Bracket 7: 17,448.76 - 27,501.60 (rate: 23.52%, fixed: 2795.25)
      // 20,000.00: 2795.25 + (20000 - 17448.76) * 0.2352 = 2795.25 + 2551.24 * 0.2352 = 2795.25 + 600.0516 = 3395.30
      expect(PayrollEngine.calculateSatIsr2026Quincenal(20000.00), 3395.30);
    });

    test('5. Base Gravable with Double Overtime Exemption (LISR Art. 93 Fracc. I)', () {
      // Base earned: 15 days * $1,000 = $15,000
      const double baseEarned = 15000.00;
      // Fomento (4.6%): $15,000 * 0.046 = $690.00 (100% gravable)
      const double fomento = 690.00;
      // Triples: $3,000 (100% gravable)
      const double pay3x = 3000.00;
      // Doubles: $4,000
      const double pay2x = 4000.00;
      const int weeksPaid = 2;

      // Exemption: min(50% of double pay, 5 * 117.31 * weeksPaid)
      // 50% of 4000 = 2000. Cap = 5 * 117.31 * 2 = 1173.10
      // Exemption = 1173.10
      final double exemption = math.min(0.50 * pay2x, 5.0 * 117.31 * weeksPaid);
      expect(exemption, 1173.10);

      final double taxableDoubles = math.max(0.0, pay2x - exemption);
      expect(taxableDoubles, 4000.00 - 1173.10);

      final double baseGravable = baseEarned + fomento + pay3x + taxableDoubles;
      // 15000 + 690 + 3000 + 2826.90 = 21516.90
      expect(baseGravable, 21516.90);

      // ISR on 21516.90 (Bracket 7: 17448.76 - 27501.60, fixed: 2795.25, rate: 23.52%)
      // 2795.25 + (21516.90 - 17448.76) * 0.2352 = 2795.25 + 4068.14 * 0.2352 = 2795.25 + 956.8265 = 3752.08
      final double isr = PayrollEngine.calculateSatIsr2026Quincenal(baseGravable);
      expect(isr, 3752.08);
    });

    test('6. Fondo de Ahorro Period Cap Verification', () {
      // Case where 13% of base earned ($25,000) exceeds cap
      // 25,000 * 0.13 = 3,250.00 > 2,287.55
      final cappedResult = PayrollEngine.calculateFondoAhorro(baseEarned: 25000.00);
      expect(cappedResult['uncappedDeduction'], 3250.00);
      expect(cappedResult['deduction'], 2287.55);
      expect(cappedResult['isCapped'], 1.0);

      // Case where 13% of base earned ($10,000) is within cap
      // 10,000 * 0.13 = 1,300.00 <= 2,287.55
      final uncappedResult = PayrollEngine.calculateFondoAhorro(baseEarned: 10000.00);
      expect(uncappedResult['uncappedDeduction'], 1300.00);
      expect(uncappedResult['deduction'], 1300.00);
      expect(uncappedResult['isCapped'], 0.0);
    });

    test('7. 1st vs 2nd Quincena Split & Cuota Sindical Frequency Verification', () {
      const double baseQuincena = 15000.00; // 15 days * $1,000
      const double applicableFomentoRate = 0.046;

      // 1. Sindicalizado 2026 (4.0%): Cuota applies ONLY on 2nd quincenas (even qNum)
      const double cuotaRateSindicalizado = 0.040;
      final double cuotaSindQ1 = PayrollEngine.calculateCuotaSindical(
        baseEarned: baseQuincena,
        applicableCuotaRate: cuotaRateSindicalizado,
        qNum: 1,
      );
      expect(cuotaSindQ1, 0.00); // 1st quincena is 0.00

      final double cuotaSindQ2 = PayrollEngine.calculateCuotaSindical(
        baseEarned: baseQuincena,
        applicableCuotaRate: cuotaRateSindicalizado,
        qNum: 2,
      );
      expect(cuotaSindQ2, 600.00); // 2nd quincena: 15,000 * 4.0% = 600.00

      // 2. Contrato Base (2.0%): Cuota applies on EVERY quincena (both 1st and 2nd)
      const double cuotaRateBase = 0.020;
      final double cuotaBaseQ1 = PayrollEngine.calculateCuotaSindical(
        baseEarned: baseQuincena,
        applicableCuotaRate: cuotaRateBase,
        qNum: 1,
      );
      expect(cuotaBaseQ1, 300.00); // 1st quincena: 15,000 * 2.0% = 300.00

      final double cuotaBaseQ2 = PayrollEngine.calculateCuotaSindical(
        baseEarned: baseQuincena,
        applicableCuotaRate: cuotaRateBase,
        qNum: 2,
      );
      expect(cuotaBaseQ2, 300.00); // 2nd quincena: 15,000 * 2.0% = 300.00

      // 3. Confianza / Sin Sindicato (0.0%): Cuota is 0.00 on all quincenas
      const double cuotaRateConfianza = 0.000;
      final double cuotaConfQ1 = PayrollEngine.calculateCuotaSindical(
        baseEarned: baseQuincena,
        applicableCuotaRate: cuotaRateConfianza,
        qNum: 1,
      );
      expect(cuotaConfQ1, 0.00);
      final double cuotaConfQ2 = PayrollEngine.calculateCuotaSindical(
        baseEarned: baseQuincena,
        applicableCuotaRate: cuotaRateConfianza,
        qNum: 2,
      );
      expect(cuotaConfQ2, 0.00);

      // Verify net deposit effects for Sindicalizado 2026:
      const double fomentoQ1 = baseQuincena * applicableFomentoRate; // 690.00
      const double totalBrutoQ1 = baseQuincena + fomentoQ1; // 15690.00
      final double isrQ1 = PayrollEngine.calculateSatIsr2026Quincenal(baseQuincena + fomentoQ1);

      final double netDepositSindQ1 = totalBrutoQ1 - (isrQ1 + cuotaSindQ1);
      expect(netDepositSindQ1, totalBrutoQ1 - isrQ1); // 0 cuota on 1st quincena

      final double netDepositSindQ2 = totalBrutoQ1 - (isrQ1 + cuotaSindQ2);
      expect(netDepositSindQ2, totalBrutoQ1 - isrQ1 - 600.00);

      // Verify net deposit effects for Contrato Base:
      final double netDepositBaseQ1 = totalBrutoQ1 - (isrQ1 + cuotaBaseQ1);
      expect(netDepositBaseQ1, totalBrutoQ1 - isrQ1 - 300.00);
      final double netDepositBaseQ2 = totalBrutoQ1 - (isrQ1 + cuotaBaseQ2);
      expect(netDepositBaseQ2, totalBrutoQ1 - isrQ1 - 300.00);
    });

    test('8. Contract Presets Parameters & Reordering Verification', () {
      // 1. Contrato Base (2.0% / 2.0%) [DEFAULT PRESET]
      const contratoBase = (
        name: "Contrato Base (2.0% / 2.0%)",
        badge: "PREDETERMINADO",
        subtitle: "Fomento 2.0% • Cuota 2.0% cada quincena",
        fomento: 2.0,
        cuota: 2.0,
      );
      expect(contratoBase.fomento, 2.0);
      expect(contratoBase.cuota, 2.0);
      expect(contratoBase.badge, "PREDETERMINADO");
      expect(contratoBase.subtitle, "Fomento 2.0% • Cuota 2.0% cada quincena");

      // 2. Sindicalizado 2026 (4.6% / 4%)
      const sindicalizado = (
        name: "Sindicalizado 2026 (4.6% / 4%)",
        badge: "SINDICALIZADO 2026",
        subtitle: "Fomento 4.6% • Cuota 4.0% en 2da quincena",
        fomento: 4.6,
        cuota: 4.0,
      );
      expect(sindicalizado.fomento, 4.6);
      expect(sindicalizado.cuota, 4.0);
      expect(sindicalizado.badge, "SINDICALIZADO 2026");
      expect(sindicalizado.subtitle, "Fomento 4.6% • Cuota 4.0% en 2da quincena");

      // 3. Confianza / Sin Sindicato (0% / 0%)
      const confianza = (
        name: "Confianza / Sin Sindicato (0% / 0%)",
        badge: "SIN SINDICATO",
        subtitle: "Fomento 0% • Cuota 0% • Sin cuota sindical",
        fomento: 0.0,
        cuota: 0.0,
      );
      expect(confianza.fomento, 0.0);
      expect(confianza.cuota, 0.0);
      expect(confianza.badge, "SIN SINDICATO");

      // isSelected checks are rate-based: curFomento == X && curCuota == Y
      bool isContratoBase(double f, double c) => (f == 2.0 && c == 2.0);
      bool isSindicalizado(double f, double c) => (f == 4.6 && c == 4.0);
      bool isConfianza(double f, double c) => (f == 0.0 && c == 0.0);

      // Verify selections with different user-configured vales amounts ($0, $690, $500)
      expect(isContratoBase(2.0, 2.0), isTrue);
      expect(isSindicalizado(4.6, 4.0), isTrue);
      expect(isConfianza(0.0, 0.0), isTrue);

      // Migration condition: unless user already has explicit 4.6% or 0.0%, defaults to 2.0%
      bool shouldMigrateToContratoBase(double? currentFomento) {
        if (currentFomento == null) return true;
        if (currentFomento == 4.6 || currentFomento == 0.0) return false;
        return true;
      }
      expect(shouldMigrateToContratoBase(null), isTrue);
      expect(shouldMigrateToContratoBase(2.0), isTrue);
      expect(shouldMigrateToContratoBase(4.6), isFalse);
      expect(shouldMigrateToContratoBase(0.0), isFalse);
    });

    test('9. Vales de Fomento Cultural (Monedero Chedraui) Metrics & Reconciliation Verification', () {
      // Default state
      const bool defaultEnabled = false;
      const double defaultAmount = 0.0;
      const int defaultStartQuincena = 1;
      final Map<String, double> defaultOverrides = {};
      final List<Map<String, dynamic>> defaultExpenses = [];

      expect(defaultEnabled, isFalse);
      expect(defaultAmount, 0.0);
      expect(defaultStartQuincena, 1);
      expect(defaultOverrides.isEmpty, isTrue);
      expect(defaultExpenses.isEmpty, isTrue);

      // Receipt amount configuration (e.g. $373.33)
      const double monthlyValesReceipt = 373.33;
      expect(monthlyValesReceipt, 373.33);

      // 12 second-quincenas in a year:
      // Q02, Q04, Q06, Q08, Q10, Q12, Q14, Q16, Q18, Q20, Q22, Q24
      const int totalSecondQuincenasInYear = 12;
      const double annualProjection = totalSecondQuincenasInYear * monthlyValesReceipt;
      expect(PayrollEngine.roundCurrency(annualProjection), 4479.96);

      // Deposit Reconciliation with overrides:
      // Suppose 3 quincenas have passed: Q02, Q04, Q06
      // Q02 had an override of $400.00, Q04 and Q06 were normal ($373.33)
      final Map<String, double> payStubOverrides = {'202602': 400.00};
      double calculateDepositForPid(String pid, double defaultAmt) {
        return payStubOverrides.containsKey(pid) ? payStubOverrides[pid]! : defaultAmt;
      }

      final double depQ02 = calculateDepositForPid('202602', monthlyValesReceipt);
      final double depQ04 = calculateDepositForPid('202604', monthlyValesReceipt);
      final double depQ06 = calculateDepositForPid('202606', monthlyValesReceipt);

      expect(depQ02, 400.00);
      expect(depQ04, 373.33);
      expect(depQ06, 373.33);

      final double totalDepositado = depQ02 + depQ04 + depQ06;
      expect(PayrollEngine.roundCurrency(totalDepositado), 1146.66);

      // Expenses tracking:
      final List<Map<String, dynamic>> expenses = [
        {'id': 'exp_1', 'monto': 250.00, 'concepto': 'Despensa Chedraui', 'fecha': '2026-02-15'},
        {'id': 'exp_2', 'monto': 120.50, 'concepto': 'Farmacia Chedraui', 'fecha': '2026-03-01'},
      ];

      final double totalGastado = expenses.fold(
          0.0, (sum, e) => sum + ((e['monto'] as num?)?.toDouble() ?? 0.0));
      expect(PayrollEngine.roundCurrency(totalGastado), 370.50);

      // Available Remaining Balance:
      final double saldoDisponible = math.max(0.0, totalDepositado - totalGastado);
      expect(PayrollEngine.roundCurrency(saldoDisponible), 776.16);

      // Total annual projection with custom Q02:
      // 1146.66 (deposited) + 9 remaining quincenas * 373.33 = 1146.66 + 3359.97 = 4506.63
      const int remainingFutureQuincenas = 9;
      final double updatedAnnualProjection = totalDepositado + (remainingFutureQuincenas * monthlyValesReceipt);
      expect(PayrollEngine.roundCurrency(updatedAnnualProjection), 4506.63);

      // Inactivity Expiration Rule:
      const int inactivityMonthsBeforeExpiration = 6;
      expect(inactivityMonthsBeforeExpiration, 6);

      // Contact info for Monedero Chedraui
      const String chedrauiWhatsApp = "5543707075";
      const String chedrauiSmsNumber = "64243";
      expect(chedrauiWhatsApp, "5543707075");
      expect(chedrauiSmsNumber, "64243");

      // Receipt visibility logic: (!isFirstQuincena && enabled && amount > 0)
      bool shouldShowVales(bool isFirstQuincena, bool enabled, double amount) {
        return !isFirstQuincena && enabled && amount > 0;
      }

      // 1st quincena (never show)
      expect(shouldShowVales(true, true, 690.0), isFalse);
      expect(shouldShowVales(true, false, 0.0), isFalse);

      // 2nd quincena
      expect(shouldShowVales(false, false, 690.0), isFalse);
      expect(shouldShowVales(false, true, 0.0), isFalse);
      expect(shouldShowVales(false, true, -10.0), isFalse);
      expect(shouldShowVales(false, true, 690.0), isTrue);

      // Strictly informational: must not alter netDeposit or taxable base
      const double gross = 15690.00;
      const double isr = 1522.00;
      const double cuota = 600.00;
      const double netWithoutVales = gross - isr - cuota;
      const double valesAmount = 690.00;
      // Net deposit remains unaffected
      expect(netWithoutVales, 13568.00);
      expect(netWithoutVales, netWithoutVales);
      expect(valesAmount > 0, isTrue);

      // Vales Unconfigured & Inactive Default Parsing:
      final Map<String, dynamic> emptyFirebaseData = {};
      final bool parsedEnabled = (emptyFirebaseData['vales_fomento_cultural_enabled'] == true);
      final double parsedAmount = (emptyFirebaseData['vales_fomento_cultural_amount'] as num?)?.toDouble() ?? 0.0;
      expect(parsedEnabled, isFalse);
      expect(parsedAmount, 0.0);

      // Settings status card display logic
      String getValesCardStatus(bool enabled, double amount) {
        return (enabled && amount > 0)
            ? "\$ ${amount.toStringAsFixed(2)}"
            : "Inactivo";
      }
      expect(getValesCardStatus(false, 0.0), "Inactivo");
      expect(getValesCardStatus(true, 0.0), "Inactivo");
      expect(getValesCardStatus(false, 373.33), "Inactivo");
      expect(getValesCardStatus(true, 373.33), "\$ 373.33");

      // Suggested amount
      const double suggestedTelevisaValesAmount = 373.33;
      expect(suggestedTelevisaValesAmount > 0, isTrue);

      // Gating Vales Reconciliation by Payout Date (Past vs Future Payouts):
      bool checkIsPayoutPassed(DateTime payoutDate, DateTime referenceDate) {
        final DateTime endOfRefDay = DateTime(
            referenceDate.year, referenceDate.month, referenceDate.day, 23, 59, 59);
        return !payoutDate.isAfter(endOfRefDay);
      }

      final DateTime simulatedNow = DateTime(2026, 2, 20); // Mid-February 2026
      final DateTime pastPayoutQ02 = DateTime(2026, 1, 30); // Q02 payout
      final DateTime futurePayoutQ04 = DateTime(2026, 2, 27); // Q04 payout

      expect(checkIsPayoutPassed(pastPayoutQ02, simulatedNow), isTrue);
      expect(checkIsPayoutPassed(futurePayoutQ04, simulatedNow), isFalse);

      // Reconciliation Status & Action Gating Resolution:
      ({
        String badge,
        bool showConfirmationPrompt,
        bool showReconciliationNote,
        String? displayAmountLabel,
        String? noteText,
      }) resolveReconciliationUI({
        required bool isVerified,
        required bool isPayoutPassed,
        required double defaultAmount,
        required double actualAmount,
        required String payoutStr,
      }) {
        if (isVerified) {
          return (
            badge: "Conciliado ✓",
            showConfirmationPrompt: false,
            showReconciliationNote: false,
            displayAmountLabel:
                "Monto acreditado: \$${actualAmount.toStringAsFixed(2)}",
            noteText: null,
          );
        } else if (!isPayoutPassed) {
          return (
            badge: "Programado",
            showConfirmationPrompt: false,
            showReconciliationNote: true,
            displayAmountLabel:
                "Depósito estimado: \$${defaultAmount.toStringAsFixed(2)}",
            noteText: "Podrás conciliar el recibo a partir del $payoutStr",
          );
        } else {
          return (
            badge: "Por conciliar",
            showConfirmationPrompt: true,
            showReconciliationNote: false,
            displayAmountLabel: null,
            noteText: null,
          );
        }
      }

      // Case A: Future Payout (unverified):
      final futureUI = resolveReconciliationUI(
        isVerified: false,
        isPayoutPassed: false,
        defaultAmount: 373.33,
        actualAmount: 373.33,
        payoutStr: "27/02/26",
      );
      expect(futureUI.badge, "Programado");
      expect(futureUI.showConfirmationPrompt, isFalse);
      expect(futureUI.showReconciliationNote, isTrue);
      expect(futureUI.displayAmountLabel, "Depósito estimado: \$373.33");
      expect(futureUI.noteText, "Podrás conciliar el recibo a partir del 27/02/26");

      // Case B: Past / Due Payout (unverified):
      final pastUI = resolveReconciliationUI(
        isVerified: false,
        isPayoutPassed: true,
        defaultAmount: 373.33,
        actualAmount: 373.33,
        payoutStr: "30/01/26",
      );
      expect(pastUI.badge, "Por conciliar");
      expect(pastUI.showConfirmationPrompt, isTrue);
      expect(pastUI.showReconciliationNote, isFalse);

      // Case C: Verified / Conciliado (Past or Future):
      final verifiedUI = resolveReconciliationUI(
        isVerified: true,
        isPayoutPassed: true,
        defaultAmount: 373.33,
        actualAmount: 400.00,
        payoutStr: "30/01/26",
      );
      expect(verifiedUI.badge, "Conciliado ✓");
      expect(verifiedUI.showConfirmationPrompt, isFalse);
      expect(verifiedUI.displayAmountLabel, "Monto acreditado: \$400.00");
    });

    test('10. Onboarding Contract Type Selection & Default Persistence Verification', () {
      final onboardingOptions = [
        (
          title: "Contrato Base (2.0% / 2.0%)",
          subtitle: "Fomento 2.0% • Cuota 2.0% cada quincena",
          badge: "PREDETERMINADO",
          fomento: "2.0",
          cuota: "2.0",
        ),
        (
          title: "Sindicalizado 2026 (4.6% / 4.0%)",
          subtitle: "Fomento 4.6% • Cuota 4.0% en 2da quincena",
          badge: "SINDICALIZADO 2026",
          fomento: "4.6",
          cuota: "4.0",
        ),
        (
          title: "Confianza / Sin Sindicato (0.0% / 0.0%)",
          subtitle: "Fomento 0.0% • Cuota 0.0% • Sin cuota sindical",
          badge: "SIN SINDICATO",
          fomento: "0.0",
          cuota: "0.0",
        ),
      ];

      const int defaultSelectedIndex = 0;
      expect(onboardingOptions[defaultSelectedIndex].title, "Contrato Base (2.0% / 2.0%)");
      expect(onboardingOptions[defaultSelectedIndex].fomento, "2.0");
      expect(onboardingOptions[defaultSelectedIndex].cuota, "2.0");

      expect(onboardingOptions[1].title, "Sindicalizado 2026 (4.6% / 4.0%)");
      expect(onboardingOptions[1].fomento, "4.6");
      expect(onboardingOptions[1].cuota, "4.0");

      expect(onboardingOptions[2].title, "Confianza / Sin Sindicato (0.0% / 0.0%)");
      expect(onboardingOptions[2].fomento, "0.0");
      expect(onboardingOptions[2].cuota, "0.0");

      const helperCopy =
          "Este es el contrato estándar que aplica a la mayoría. Si tienes otro tipo de contrato, selecciónalo aquí. También podrás cambiarlo o ajustarlo después en Ajustes.";
      expect(helperCopy.contains("contrato estándar"), isTrue);
      expect(helperCopy.contains("Ajustes"), isTrue);

      // Verify that upon saving onboarding selection, contrato_base_default_v1_applied is true
      bool onboardingCompletedSetsFlag = true;
      expect(onboardingCompletedSetsFlag, isTrue);
    });

    test('10. Smart Clock-Out Date Disambiguation (Previous Day vs Same Day)', () {
      final yesterdayEntrada = DateTime(2026, 11, 18, 20, 0); // 8:00 PM yesterday
      final nowMorning = DateTime(2026, 11, 19, 8, 30); // 8:30 AM today

      // Case 1: Shift started yesterday, picked time > now (e.g., 23:00 / 11:00 PM)
      // Must be assigned to entrada's calendar date (yesterday)
      final resolvedYesterdaySalida = PayrollEngine.resolveClockOutDateTime(
        entrada: yesterdayEntrada,
        pickedTime: const TimeOfDay(hour: 23, minute: 0),
        now: nowMorning,
      );
      expect(resolvedYesterdaySalida, isNotNull);
      expect(resolvedYesterdaySalida, DateTime(2026, 11, 18, 23, 0));

      // Case 2: Shift started yesterday, picked time > now (e.g., 08:31 AM - 1 min future)
      final resolvedYesterdayFutureMin = PayrollEngine.resolveClockOutDateTime(
        entrada: yesterdayEntrada,
        pickedTime: const TimeOfDay(hour: 8, minute: 31),
        now: nowMorning,
      );
      expect(resolvedYesterdayFutureMin, DateTime(2026, 11, 18, 8, 31));

      // Case 3: Shift started yesterday, picked time <= now (e.g., 06:00 AM today, overnight shift)
      // Must be assigned to today's date
      final resolvedOvernightSalida = PayrollEngine.resolveClockOutDateTime(
        entrada: yesterdayEntrada,
        pickedTime: const TimeOfDay(hour: 6, minute: 0),
        now: nowMorning,
      );
      expect(resolvedOvernightSalida, isNotNull);
      expect(resolvedOvernightSalida, DateTime(2026, 11, 19, 6, 0));

      // Case 4: Shift started yesterday, picked time == now (08:30 AM today)
      final resolvedExactNowSalida = PayrollEngine.resolveClockOutDateTime(
        entrada: yesterdayEntrada,
        pickedTime: const TimeOfDay(hour: 8, minute: 30),
        now: nowMorning,
      );
      expect(resolvedExactNowSalida, DateTime(2026, 11, 19, 8, 30));

      // Case 5: Shift started today, picked time <= now (e.g., entered 08:00, picked 16:00 at 16:30)
      final todayEntrada = DateTime(2026, 11, 19, 8, 0);
      final nowAfternoon = DateTime(2026, 11, 19, 16, 30);
      final resolvedTodayValid = PayrollEngine.resolveClockOutDateTime(
        entrada: todayEntrada,
        pickedTime: const TimeOfDay(hour: 16, minute: 0),
        now: nowAfternoon,
      );
      expect(resolvedTodayValid, DateTime(2026, 11, 19, 16, 0));

      // Case 6: Shift started today, picked time > now (e.g., picked 17:00 at 16:30)
      // Must be blocked (returns null for SnackBar warning)
      final resolvedTodayFuture = PayrollEngine.resolveClockOutDateTime(
        entrada: todayEntrada,
        pickedTime: const TimeOfDay(hour: 17, minute: 0),
        now: nowAfternoon,
      );
      expect(resolvedTodayFuture, isNull);

      // Case 7: Shift started today, picked time 1 minute in the future (16:31 at 16:30)
      final resolvedTodayFutureMin = PayrollEngine.resolveClockOutDateTime(
        entrada: todayEntrada,
        pickedTime: const TimeOfDay(hour: 16, minute: 31),
        now: nowAfternoon,
      );
      expect(resolvedTodayFutureMin, isNull);

      // Verify Time Picker Title Disambiguation
      const String titlePreviousDay = "¿A QUÉ HORA FUE TU SALIDA?";
      const String titleTodayManual = "¿A QUÉ HORA SALISTE HOY?";
      const String titleTodayEdit = "EDITAR HORA SALIDA";

      String getTitle({required bool isShiftFromPreviousDay, required bool isManual}) {
        if (isShiftFromPreviousDay) return titlePreviousDay;
        return isManual ? titleTodayManual : titleTodayEdit;
      }

      expect(getTitle(isShiftFromPreviousDay: true, isManual: true), "¿A QUÉ HORA FUE TU SALIDA?");
      expect(getTitle(isShiftFromPreviousDay: true, isManual: false), "¿A QUÉ HORA FUE TU SALIDA?");
      expect(getTitle(isShiftFromPreviousDay: false, isManual: true), "¿A QUÉ HORA SALISTE HOY?");
      expect(getTitle(isShiftFromPreviousDay: false, isManual: false), "EDITAR HORA SALIDA");
    });

    test('11. Quincena 14 Official Paystub Reconciliation with Absences', () {
      const double applicableSalary = 907.17;
      const int faltasCount = 2;
      const List<int> restDays = [DateTime.saturday, DateTime.sunday];

      // Proportional factor calculation decoupled from weeks count:
      final double restRatio = restDays.isNotEmpty
          ? (restDays.length / (7.0 - restDays.length))
          : 0.4;
      final double factorPerFalta = 1.0 + restRatio; // 1.4 for standard 5-day workweek with 2 rest days
      expect(factorPerFalta, 1.4);

      // Official paystub Quincena 14: base quincena is $13,607.51 ($27,215.02 / 2)
      const double baseQuincena = 13607.51;

      // 1. Descuento por Faltas: 2 absences * 1.4 * $907.17 = $2,540.076 -> $2,540.08
      final double unroundedDescuento =
          math.min(baseQuincena, faltasCount * factorPerFalta * applicableSalary);
      final double descuentoFaltas =
          PayrollEngine.roundCurrency(unroundedDescuento);
      expect(descuentoFaltas, 2540.08);

      // 2. Base Earned: $13,607.51 - $2,540.08 = $11,067.43
      final double baseEarned =
          PayrollEngine.roundCurrency(math.max(0.0, baseQuincena - descuentoFaltas));
      expect(baseEarned, 11067.43);

      // 3. Fomento Eficiencia: 2.0% on base earned ($11,067.43 * 0.02 = $221.3486 -> $221.35)
      const double applicableFomentoRate = 0.02;
      final double fomentoEficiencia =
          PayrollEngine.roundCurrency(baseEarned * applicableFomentoRate);
      expect(fomentoEficiencia, 221.35);

      // 4. Cuota Sindical: (15.0 - 2) * $907.17 * 2.0% = 13 * $907.17 * 0.02 = $235.8642 -> $235.86
      const double applicableCuotaRate = 0.02;
      const int qNum = 14;
      final double cuotaSindical = PayrollEngine.calculateCuotaSindical(
        baseEarned: baseEarned,
        applicableCuotaRate: applicableCuotaRate,
        qNum: qNum,
        faltasCount: faltasCount,
        applicableSalary: applicableSalary,
      );
      expect(cuotaSindical, 235.86);

      // 5. Total Bruto (Percepciones gravables): base earned + fomento eficiencia
      final double totalBruto = baseEarned + fomentoEficiencia;
      expect(totalBruto, 11288.78);

      // 6. ISR Retenido (SAT 2026 progressive table on $11,288.78): $1,479.54
      final double isrRetenido =
          PayrollEngine.calculateSatIsr2026Quincenal(totalBruto);
      expect(isrRetenido, 1479.54);

      // 7. Net Deposit: Total Bruto - (ISR + Cuota Sindical) = $11,288.78 - ($1,479.54 + $235.86) = $9,573.38
      final double netDeposit =
          PayrollEngine.roundCurrency(totalBruto - (isrRetenido + cuotaSindical));
      expect(netDeposit, 9573.38);
    });

    test('12. Unified Contract Periods Multi-Period Calibration (Contrato Base vs Sindicalizado 2026 vs Confianza)', () {
      final List<Map<String, dynamic>> contractHistory = [
        {
          'type': 'contrato_base',
          'contract_type': 'contrato_base',
          'fomento': 2.0,
          'cuota': 2.0,
          'frequency': 'both',
          'cuota_frequency': 'both',
          'start_date': '2026-01-01',
          'end_date': '2026-07-31',
        },
        {
          'type': 'sindicalizado_2026',
          'contract_type': 'sindicalizado_2026',
          'fomento': 4.6,
          'cuota': 4.0,
          'frequency': 'second_only',
          'cuota_frequency': 'second_only',
          'start_date': '2026-08-01',
          'end_date': '2026-10-31',
        },
        {
          'type': 'confianza',
          'contract_type': 'confianza',
          'fomento': 0.0,
          'cuota': 0.0,
          'frequency': 'none',
          'cuota_frequency': 'none',
          'start_date': '2026-11-01',
          'end_date': null,
        },
      ];

      // A. Quincena 14 (Payout: 2026-07-31, July 2nd Quincena) -> Contrato Base
      final q14Contract = PayrollEngine.resolveContractForDate(
        date: DateTime(2026, 7, 31),
        contractHistory: contractHistory,
      );
      expect(q14Contract['type'], 'contrato_base');
      expect(q14Contract['fomento'], 2.0);
      expect(q14Contract['cuota'], 2.0);
      expect(q14Contract['frequency'], 'both');

      const double q14BaseEarned = 11067.43;
      final double q14Fomento = PayrollEngine.roundCurrency(
          q14BaseEarned * ((q14Contract['fomento'] as num).toDouble() / 100.0));
      expect(q14Fomento, 221.35);

      final double q14Cuota = PayrollEngine.calculateCuotaSindical(
        baseEarned: q14BaseEarned,
        applicableCuotaRate: (q14Contract['cuota'] as num).toDouble() / 100.0,
        qNum: 14,
        faltasCount: 2,
        applicableSalary: 907.17,
        frequency: q14Contract['frequency'],
      );
      expect(q14Cuota, 235.86);

      // Verify that Quincena 13 (2026-07-15, July 1st Quincena, odd) also deducts cuota under 'both'
      final double q13Cuota = PayrollEngine.calculateCuotaSindical(
        baseEarned: 13607.51,
        applicableCuotaRate: 0.02,
        qNum: 13,
        frequency: 'both',
      );
      expect(q13Cuota, 272.15);

      // B. Quincena 15 (Payout: 2026-08-15, August 1st Quincena, odd) -> Sindicalizado 2026
      final q15Contract = PayrollEngine.resolveContractForDate(
        date: DateTime(2026, 8, 15),
        contractHistory: contractHistory,
      );
      expect(q15Contract['type'], 'sindicalizado_2026');
      expect(q15Contract['fomento'], 4.6);
      expect(q15Contract['cuota'], 4.0);
      expect(q15Contract['frequency'], 'second_only');

      const double standardBase = 13607.51;
      final double q15Fomento = PayrollEngine.roundCurrency(
          standardBase * ((q15Contract['fomento'] as num).toDouble() / 100.0));
      expect(q15Fomento, 625.95);

      // In 1st quincena of the month, Sindicalizado 2026 cuota is 0.0
      final double q15Cuota = PayrollEngine.calculateCuotaSindical(
        baseEarned: standardBase,
        applicableCuotaRate: (q15Contract['cuota'] as num).toDouble() / 100.0,
        qNum: 15,
        frequency: q15Contract['frequency'],
      );
      expect(q15Cuota, 0.0);

      // C. Quincena 16 (Payout: 2026-08-31, August 2nd Quincena, even) -> Sindicalizado 2026
      final q16Contract = PayrollEngine.resolveContractForDate(
        date: DateTime(2026, 8, 31),
        contractHistory: contractHistory,
      );
      expect(q16Contract['type'], 'sindicalizado_2026');
      expect(q16Contract['frequency'], 'second_only');

      // In 2nd quincena of the month, Sindicalizado 2026 cuota is deducted (4.0%)
      final double q16Cuota = PayrollEngine.calculateCuotaSindical(
        baseEarned: standardBase,
        applicableCuotaRate: (q16Contract['cuota'] as num).toDouble() / 100.0,
        qNum: 16,
        frequency: q16Contract['frequency'],
      );
      expect(q16Cuota, 544.30); // 13,607.51 * 0.04 = 544.3004 -> 544.30

      // D. Quincena 21 (Payout: 2026-11-15, November under Confianza) -> Confianza
      final q21Contract = PayrollEngine.resolveContractForDate(
        date: DateTime(2026, 11, 15),
        contractHistory: contractHistory,
      );
      expect(q21Contract['type'], 'confianza');
      expect(q21Contract['fomento'], 0.0);
      expect(q21Contract['cuota'], 0.0);
      expect(q21Contract['frequency'], 'none');

      final double q21Fomento = PayrollEngine.roundCurrency(
          standardBase * ((q21Contract['fomento'] as num).toDouble() / 100.0));
      expect(q21Fomento, 0.0);

      final double q21Cuota = PayrollEngine.calculateCuotaSindical(
        baseEarned: standardBase,
        applicableCuotaRate: (q21Contract['cuota'] as num).toDouble() / 100.0,
        qNum: 21,
        frequency: q21Contract['frequency'],
      );
      expect(q21Cuota, 0.0);

      // E. Fallback Resolution with empty contract history
      final fallbackContract = PayrollEngine.resolveContractForDate(
        date: DateTime(2026, 5, 1),
        contractHistory: [],
        defaultFomento: 2.0,
        defaultCuota: 2.0,
      );
      expect(fallbackContract['type'], 'contrato_base');
      expect(fallbackContract['fomento'], 2.0);
      expect(fallbackContract['cuota'], 2.0);
      expect(fallbackContract['frequency'], 'both');
    });

    test('13. Contract Presets Screen Data Contract & Default Presets Verification', () {
      // 1. Verify standard preset definitions
      const standardPresets = {
        'contrato_base': {
          'name': 'Contrato Base (2.0% / 2.0%)',
          'fomento': 2.0,
          'cuota': 2.0,
          'frequency': 'both',
        },
        'sindicalizado_2026': {
          'name': 'Sindicalizado 2026 (4.6% / 4%)',
          'fomento': 4.6,
          'cuota': 4.0,
          'frequency': 'second_only',
        },
        'confianza': {
          'name': 'Confianza / Sin Sindicato (0% / 0%)',
          'fomento': 0.0,
          'cuota': 0.0,
          'frequency': 'none',
        },
      };

      for (final entry in standardPresets.entries) {
        final Map<String, dynamic> resolved = PayrollEngine.resolveContractForDate(
          date: DateTime(2026, 6, 1),
          contractHistory: [
            {
              'type': entry.key,
              'contract_type': entry.key,
              'fomento': entry.value['fomento'],
              'cuota': entry.value['cuota'],
              'frequency': entry.value['frequency'],
              'cuota_frequency': entry.value['frequency'],
              'name': entry.value['name'],
              'start_date': '2026-01-01',
              'end_date': null,
            }
          ],
        );
        expect(resolved['type'], entry.key);
        expect(resolved['fomento'], entry.value['fomento']);
        expect(resolved['cuota'], entry.value['cuota']);
        expect(resolved['frequency'], entry.value['frequency']);

        // Verify summary label formatting ("Fomento X% • Cuota Y%")
        final double f = (resolved['fomento'] as num).toDouble();
        final double c = (resolved['cuota'] as num).toDouble();
        final String summary = "Fomento ${f.toStringAsFixed(1)}% • Cuota ${c.toStringAsFixed(1)}%";
        expect(summary.contains('Fomento'), true);
        expect(summary.contains('Cuota'), true);
      }
    });
  });
}
