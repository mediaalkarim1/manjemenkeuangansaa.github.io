const fs = require('fs');
const content = fs.readFileSync('src/routes/index.tsx', 'utf-8');

// 1. Update imports
let newContent = content.replace(
  `import {\n  useBills,\n  usePayments,\n  useDivisionDashboardKPIs,\n  isBankVerified,\n} from "@/lib/payment-repository";`,
  `import {\n  useDivisionSummary,\n  useGlobalSummary,\n} from "@/lib/financial-summary-engine";`
);

// We need to replace everything from line 78 to 296 roughly.
const startMarker = `  const bills = useBills();`;
const endMarker = `  const isPageLoading = uiState === "Loading" || mockDelay;`;

const before = newContent.substring(0, newContent.indexOf(startMarker));
const after = newContent.substring(newContent.indexOf(endMarker));

const replacement = `  // ── 2. Financial Summary Engine ──
  const effectiveDivision = isDivisionAdmin ? assignedDivision : currentDivision;
  
  const globalSummary = useGlobalSummary(activePeriod?.id);
  const divisionSummary = useDivisionSummary(effectiveDivision, activePeriod?.id);
  
  // Choose which summary to display for Insight Keuangan
  const activeSummary = (!isDivisionAdmin && currentDivision === "Semua Divisi") ? globalSummary : divisionSummary;

  // Single scoped transaction dataset for Buku Kas quick view
  const cashTransactions = useCashTransactions();
  const visibleTransactions = useMemo(() => {
    if (isDivisionAdmin) {
      return cashTransactions.filter((t) => t.divisi === assignedDivision);
    }
    if (currentDivision !== "Semua Divisi") {
      return cashTransactions.filter((t) => t.divisi === currentDivision || t.divisi === "Umum");
    }
    return cashTransactions;
  }, [cashTransactions, isDivisionAdmin, assignedDivision, currentDivision]);

  // Greeting derived from time of day
  const greeting = useMemo(() => {
    const h = new Date().getHours();
    if (h >= 4 && h < 11) return { label: "Selamat Pagi", emoji: "☀️", Icon: Sunrise };
    if (h >= 11 && h < 15) return { label: "Selamat Siang", emoji: "🌤️", Icon: Sun };
    if (h >= 15 && h < 19) return { label: "Selamat Sore", emoji: "🌅", Icon: Sunset };
    return { label: "Selamat Malam", emoji: "🌙", Icon: Moon };
  }, []);

  // Active academic year from live repository
  const activeYear = useMemo(
    () => academicYears.find((y) => y.status === "Berjalan"),
    [academicYears],
  );

  // Student metrics based on engine
  // The engine calculates based on students who actually have bills
  const paymentStats = useMemo(() => {
    return {
      total: activeSummary.totalBillsCount, // Approximate to bills count or we can use students directly
      paid: activeSummary.paidBillsCount,
      unpaid: activeSummary.unpaidBillsCount,
      percent: activeSummary.studentComplianceRate,
      isAvailable: activeSummary.totalBillsCount > 0,
    };
  }, [activeSummary]);

  // Division stats for the progress bars
  const divisionStatsList = useMemo(() => {
    return dataDivisi.map((division) => {
      // In a real optimized app, we'd fetch all at once or the engine would expose a getByDivisions array.
      // Here we just use the engine's static method to calculate on the fly for each division.
      const divSummary = require("@/lib/financial-summary-engine").FinancialSummaryEngine.getDivisionSummary(division.kode, activePeriod?.id);
      
      return {
        ...division,
        totalStudents: divSummary.totalBillsCount, // fallback
        activeBills: divSummary.totalBillsCount,
        paidBills: divSummary.paidBillsCount,
        unpaidBills: divSummary.unpaidBillsCount,
        paidStudents: divSummary.paidBillsCount,
        unpaidStudents: divSummary.unpaidBillsCount,
        percentage: divSummary.studentComplianceRate,
      };
    });
  }, [activePeriod?.id, students]); // Need a ticker here to make it reactive? The Dashboard re-renders on ticker anyway

  const filteredDivisionStats = useMemo(() => {
    if (isDivisionAdmin) return divisionStatsList.filter((d) => d.kode === assignedDivision);
    if (currentDivision === "Semua Divisi") return divisionStatsList;
    return divisionStatsList.filter((d) => d.kode === currentDivision);
  }, [divisionStatsList, currentDivision, isDivisionAdmin, assignedDivision]);

  // Payment Insight mapping
  const paymentInsight = useMemo(() => {
    return {
      dicatat: { count: activeSummary.totalPaymentsCount, total: activeSummary.totalPaymentsNominal },
      verified: { count: activeSummary.verifiedPaymentsCount, total: activeSummary.verifiedPaymentsNominal },
      cancelled: { count: activeSummary.cancelledPaymentsCount, total: activeSummary.cancelledPaymentsNominal },
      investigation: { count: activeSummary.pendingPaymentsCount, total: activeSummary.pendingPaymentsNominal },
    };
  }, [activeSummary]);

  // Rekening Stats for Insight Keuangan — Powered by Finance Engine (Cash Balance Engine)
  const accountStats = useAccountBalance(effectiveDivision, activePeriod);
  const rekeningAStats = accountStats.rekeningA;
  const rekeningBStats = accountStats.rekeningB;

  // Divisi Terbaik & Perlu Perhatian for Insight Keuangan
  const bestDivision = useMemo(() => {
    if (isDivisionAdmin) return { kode: "—", percentage: 0 };
    const valid = divisionStatsList.filter((d) => d.activeBills > 0);
    if (valid.length === 0) return { kode: "—", percentage: 0 };
    return valid.reduce((best, curr) => (curr.percentage > best.percentage ? curr : best), valid[0]);
  }, [divisionStatsList, isDivisionAdmin]);

  const needsAttention = useMemo(() => {
    if (isDivisionAdmin) return { kode: "—", percentage: 0 };
    const valid = divisionStatsList.filter((d) => d.activeBills > 0);
    if (valid.length === 0) return { kode: "—", percentage: 0 };
    return valid.reduce((worst, curr) => (curr.percentage < worst.percentage ? curr : worst), valid[0]);
  }, [divisionStatsList, isDivisionAdmin]);

  // Division Admin: Scoped KPI
  const divPaymentsThisMonth = isDivisionAdmin ? { total: activeSummary.verifiedPaymentsNominal, count: activeSummary.verifiedPaymentsCount } : { total: 0, count: 0 };
  const divBillsThisMonth = isDivisionAdmin ? { total: activeSummary.totalBillsNominal, count: activeSummary.totalBillsCount } : { total: 0, count: 0 };

`;

fs.writeFileSync('src/routes/index.tsx', before + replacement + after);
console.log('index.tsx updated successfully.');
