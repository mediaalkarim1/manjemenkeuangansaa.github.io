-- ============================================================================
-- SAA FINANCE — CLOUDFLARE D1 (SQLite) PRODUCTION RELATIONAL SCHEMA
-- ============================================================================
-- Designed for zero-data-loss migration from LocalStorage to Cloudflare D1.
-- Enforces Referential Integrity, UUID keys, Soft Deletion, and Audit trails.
-- ============================================================================

PRAGMA foreign_keys = ON;

-- ----------------------------------------------------------------------------
-- 1. USERS TABLE (Super Admin, Bendahara, Division Admin)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,                       -- UUID v4
  username TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  email TEXT,
  password_hash TEXT NOT NULL,               -- SHA-256 hashed password
  role TEXT NOT NULL,                        -- 'Super Admin' | 'Admin Keuangan' | 'Division Admin'
  division TEXT NOT NULL DEFAULT 'ALL',      -- 'ALL' | 'Daycare' | 'KB' | 'TK' | 'SD'
  division_scope TEXT NOT NULL DEFAULT 'Semua',
  status TEXT NOT NULL DEFAULT 'Aktif',
  last_login_at TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 2. ACADEMIC YEARS TABLE (Tahun Ajaran)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS academic_years (
  id TEXT PRIMARY KEY,                       -- UUID v4
  name TEXT NOT NULL UNIQUE,                 -- e.g. "2024/2025"
  status TEXT NOT NULL DEFAULT 'Aktif',      -- 'Aktif' | 'Non-Aktif'
  is_active INTEGER NOT NULL DEFAULT 0 CHECK (is_active IN (0, 1)),
  start_date TEXT,
  end_date TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 3. CLASSROOMS TABLE (Kelas Siswa)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS classrooms (
  id TEXT PRIMARY KEY,                       -- UUID v4
  name TEXT NOT NULL,                        -- e.g. "1A", "KB-A"
  division TEXT NOT NULL,                    -- 'Daycare' | 'KB' | 'TK' | 'SD'
  grade TEXT,                                -- '1' | '2' | '3' | ...
  academic_year_id TEXT NOT NULL,
  capacity INTEGER NOT NULL DEFAULT 30,
  homeroom_teacher_id TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE RESTRICT,
  FOREIGN KEY (homeroom_teacher_id) REFERENCES teachers(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 4. GUARDIANS TABLE (Orang Tua / Wali Siswa)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS guardians (
  id TEXT PRIMARY KEY,                       -- UUID v4
  name TEXT NOT NULL,
  relation TEXT NOT NULL,                    -- 'Ayah' | 'Ibu' | 'Wali'
  phone TEXT,
  email TEXT,
  address TEXT,
  occupation TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 5. STUDENTS TABLE (Siswa)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS students (
  id TEXT PRIMARY KEY,                       -- UUID v4
  nis TEXT UNIQUE,
  nisn TEXT UNIQUE,
  name TEXT NOT NULL,
  nickname TEXT,
  gender TEXT,                               -- 'Laki-laki' | 'Perempuan'
  division TEXT NOT NULL,                    -- 'Daycare' | 'KB' | 'TK' | 'SD'
  classroom_id TEXT NOT NULL,
  guardian_id TEXT,
  academic_year_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Aktif',      -- 'Aktif' | 'Cuti' | 'Alumni'
  birth_place TEXT,
  birth_date TEXT,
  address TEXT,
  virtual_account TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE RESTRICT,
  FOREIGN KEY (guardian_id) REFERENCES guardians(id) ON DELETE SET NULL,
  FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE RESTRICT,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 6. TEACHERS TABLE (Guru & Staff)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS teachers (
  id TEXT PRIMARY KEY,                       -- UUID v4
  name TEXT NOT NULL,
  division TEXT NOT NULL,                    -- 'Daycare' | 'KB' | 'TK' | 'SD' | 'ALL'
  role_title TEXT,                           -- e.g. "Wali Kelas 1A"
  status TEXT NOT NULL DEFAULT 'Aktif',      -- 'Aktif' | 'Cuti' | 'Non-Aktif'
  phone TEXT,
  email TEXT,
  address TEXT,
  bank_name TEXT,
  bank_account TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 7. STUDENT ASSIGNMENTS TABLE (Kenaikan & Penugasan Siswa)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS student_assignments (
  id TEXT PRIMARY KEY,                       -- UUID v4
  student_id TEXT NOT NULL,
  from_classroom_id TEXT,
  to_classroom_id TEXT NOT NULL,
  from_academic_year_id TEXT,
  to_academic_year_id TEXT NOT NULL,
  promotion_date TEXT NOT NULL,
  promotion_type TEXT NOT NULL,              -- 'KENAIKAN_KELAS' | 'TINGGAL_KELAS' | 'LULUS' | 'MUTASI' | 'MASUK_BARU'
  notes TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE RESTRICT,
  FOREIGN KEY (from_classroom_id) REFERENCES classrooms(id) ON DELETE SET NULL,
  FOREIGN KEY (to_classroom_id) REFERENCES classrooms(id) ON DELETE RESTRICT,
  FOREIGN KEY (from_academic_year_id) REFERENCES academic_years(id) ON DELETE SET NULL,
  FOREIGN KEY (to_academic_year_id) REFERENCES academic_years(id) ON DELETE RESTRICT,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 8. SPP RATES TABLE (Tarif Dasar SPP per Divisi & Tahun Ajaran)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS spp_rates (
  id TEXT PRIMARY KEY,                       -- UUID v4
  division TEXT NOT NULL,                    -- 'Daycare' | 'KB' | 'TK' | 'SD'
  academic_year_id TEXT NOT NULL,
  amount INTEGER NOT NULL,
  label TEXT NOT NULL,                       -- e.g. "SD Kelas 1-3"
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  UNIQUE(division, academic_year_id),
  FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE RESTRICT,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 9. SPP OVERRIDES TABLE (Diskon, Beasiswa & Penyesuaian SPP Siswa)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS spp_overrides (
  id TEXT PRIMARY KEY,                       -- UUID v4
  student_id TEXT NOT NULL,
  override_type TEXT NOT NULL,               -- 'SCHOLARSHIP' | 'DISCOUNT_SIBLING' | 'DISCOUNT_SPECIAL' | 'CUSTOM'
  discount_amount INTEGER NOT NULL DEFAULT 0,
  custom_amount INTEGER,
  reason TEXT NOT NULL,
  valid_from_month TEXT,
  valid_until_month TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE RESTRICT,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 10. FINANCIAL PERIODS TABLE (Periode Akuntansi Bulanan)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS financial_periods (
  id TEXT PRIMARY KEY,                       -- UUID v4
  name TEXT NOT NULL UNIQUE,                 -- e.g. "Juli 2026"
  month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
  year INTEGER NOT NULL,
  opening_balance_a INTEGER NOT NULL DEFAULT 0,
  opening_balance_b INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED')),
  closed_at TEXT,
  closed_by TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (closed_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 11. BILLS TABLE (Tagihan SPP Siswa)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bills (
  id TEXT PRIMARY KEY,                       -- UUID v4
  student_id TEXT NOT NULL,
  classroom_id TEXT NOT NULL,
  academic_year_id TEXT NOT NULL,
  month_name TEXT NOT NULL,                  -- 'Juli', 'Agustus', etc.
  year INTEGER NOT NULL,
  amount INTEGER NOT NULL,                   -- Final tagihan SPP bulanan
  paid_amount INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL,                      -- 'Belum Bayar' | 'Membayar sebagian' | 'Lunas'
  due_date TEXT,
  spp_rate_id TEXT,
  override_id TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE RESTRICT,
  FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE RESTRICT,
  FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE RESTRICT,
  FOREIGN KEY (spp_rate_id) REFERENCES spp_rates(id) ON DELETE SET NULL,
  FOREIGN KEY (override_id) REFERENCES spp_overrides(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 12. PAYMENTS TABLE (Transaksi Pembayaran SPP)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
  id TEXT PRIMARY KEY,                       -- UUID v4
  bill_id TEXT NOT NULL,
  student_id TEXT NOT NULL,
  payment_date TEXT NOT NULL,
  payer_name TEXT NOT NULL,
  sender_account TEXT,
  destination_account TEXT,
  amount INTEGER NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'TRANSFER',
  verification_status TEXT NOT NULL DEFAULT 'VERIFIED'
    CHECK (verification_status IN ('PENDING_BANK_VERIFICATION', 'VERIFIED', 'NEEDS_INVESTIGATION', 'CANCELLED', 'VOID')),
  verified_by TEXT,
  verified_at TEXT,
  verification_note TEXT,
  period_id TEXT,
  cancelled_at TEXT,
  cancelled_by TEXT,
  cancel_reason TEXT,
  voided_at TEXT,
  voided_by TEXT,
  void_reason TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (bill_id) REFERENCES bills(id) ON DELETE RESTRICT,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE RESTRICT,
  FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (period_id) REFERENCES financial_periods(id) ON DELETE SET NULL,
  FOREIGN KEY (cancelled_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (voided_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 13. EXPENSES TABLE (Pengeluaran Operasional Sekolah)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS expenses (
  id TEXT PRIMARY KEY,                       -- UUID v4
  date TEXT NOT NULL,
  division TEXT NOT NULL,
  category TEXT NOT NULL,
  account TEXT NOT NULL,
  amount INTEGER NOT NULL,
  description TEXT NOT NULL,
  attachment TEXT,
  expense_number TEXT UNIQUE,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'VOID')),
  void_reason TEXT,
  void_by TEXT,
  void_at TEXT,
  month INTEGER,
  year INTEGER,
  academic_year_id TEXT,
  period_id TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT NOT NULL,                  -- Harus mencatat user pencipta pengeluaran
  updated_by TEXT,

  FOREIGN KEY (void_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (academic_year_id) REFERENCES academic_years(id) ON DELETE SET NULL,
  FOREIGN KEY (period_id) REFERENCES financial_periods(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 14. CASH TRANSACTIONS TABLE (Buku Kas Umum)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cash_transactions (
  id TEXT PRIMARY KEY,                       -- UUID v4
  date TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('MASUK', 'KELUAR')),
  category TEXT NOT NULL,
  division TEXT NOT NULL DEFAULT 'ALL',
  amount INTEGER NOT NULL,
  description TEXT NOT NULL,
  account_type TEXT NOT NULL DEFAULT 'BANK' CHECK (account_type IN ('BANK', 'KAS_TUNAI')),
  reference_id TEXT,                         -- Bisa UUID payment_id atau expense_id
  reference_type TEXT,                       -- 'PAYMENT' | 'EXPENSE' | 'MANUAL' | 'SALARY'
  period_id TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (period_id) REFERENCES financial_periods(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 15. SALARY RECORDS TABLE (Payroll & Gaji Guru)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS salary_records (
  id TEXT PRIMARY KEY,                       -- UUID v4
  teacher_id TEXT NOT NULL,
  month TEXT NOT NULL,                       -- e.g. "Juli 2026"
  division TEXT NOT NULL,
  basic_salary INTEGER NOT NULL DEFAULT 0,
  allowance_structural INTEGER NOT NULL DEFAULT 0,
  allowance_functional INTEGER NOT NULL DEFAULT 0,
  allowance_transport INTEGER NOT NULL DEFAULT 0,
  allowance_meal INTEGER NOT NULL DEFAULT 0,
  allowance_other INTEGER NOT NULL DEFAULT 0,
  deduction_tax INTEGER NOT NULL DEFAULT 0,
  deduction_loan INTEGER NOT NULL DEFAULT 0,
  deduction_other INTEGER NOT NULL DEFAULT 0,
  net_salary INTEGER NOT NULL DEFAULT 0,
  payment_status TEXT NOT NULL DEFAULT 'DIBAYAR' CHECK (payment_status IN ('PENDING', 'DIBAYAR')),
  payment_date TEXT,
  period_id TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE RESTRICT,
  FOREIGN KEY (period_id) REFERENCES financial_periods(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 16. ACTIVITIES TABLE (Log Audit & Aktivitas Pengguna)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS activities (
  id TEXT PRIMARY KEY,                       -- UUID v4
  user_id TEXT,
  type TEXT NOT NULL,                        -- 'CREATE' | 'UPDATE' | 'DELETE' | 'LOGIN' | 'AUDIT'
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  division TEXT NOT NULL DEFAULT 'ALL',
  entity_type TEXT,                          -- e.g. 'PAYMENT', 'STUDENT', 'BILL', 'EXPENSE'
  entity_id TEXT,
  ip_address TEXT,
  user_agent TEXT,
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 17. SETTINGS TABLE (Pengaturan Global & Tanda Tangan Sekolah)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS settings (
  id TEXT PRIMARY KEY,                       -- Singleton UUID e.g. 'setting-global-1'
  school_name TEXT NOT NULL DEFAULT 'Sekolah Alam Al-Karim',
  npsn TEXT NOT NULL DEFAULT '20255811',
  active_academic_year_id TEXT,
  signature_bendahara TEXT DEFAULT '',
  signature_kepala_sekolah TEXT DEFAULT '',
  signature_ketua_yayasan TEXT DEFAULT '',
  
  -- Soft Delete & Audit Columns
  record_status TEXT NOT NULL DEFAULT 'Aktif' CHECK (record_status IN ('Aktif', 'Diarsipkan', 'Dihapus')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  created_by TEXT,
  updated_by TEXT,

  FOREIGN KEY (active_academic_year_id) REFERENCES academic_years(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================================================
-- PERFORMANCE & FILTERING INDEXES
-- ============================================================================
-- Optimized for high-frequency queries: student_id, teacher_id, bill_id,
-- payment_id, academic_year_id, classroom_id, division, record_status,
-- and verification_status.
-- ============================================================================

-- Classrooms Indexes
CREATE INDEX IF NOT EXISTS idx_classrooms_academic_year_id ON classrooms(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_classrooms_division ON classrooms(division);
CREATE INDEX IF NOT EXISTS idx_classrooms_record_status ON classrooms(record_status);

-- Students Indexes
CREATE INDEX IF NOT EXISTS idx_students_classroom_id ON students(classroom_id);
CREATE INDEX IF NOT EXISTS idx_students_guardian_id ON students(guardian_id);
CREATE INDEX IF NOT EXISTS idx_students_academic_year_id ON students(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_students_division ON students(division);
CREATE INDEX IF NOT EXISTS idx_students_record_status ON students(record_status);

-- Teachers Indexes
CREATE INDEX IF NOT EXISTS idx_teachers_division ON teachers(division);
CREATE INDEX IF NOT EXISTS idx_teachers_record_status ON teachers(record_status);

-- Student Assignments Indexes
CREATE INDEX IF NOT EXISTS idx_student_assignments_student_id ON student_assignments(student_id);
CREATE INDEX IF NOT EXISTS idx_student_assignments_to_classroom_id ON student_assignments(to_classroom_id);
CREATE INDEX IF NOT EXISTS idx_student_assignments_to_academic_year_id ON student_assignments(to_academic_year_id);
CREATE INDEX IF NOT EXISTS idx_student_assignments_record_status ON student_assignments(record_status);

-- SPP Rates & Overrides Indexes
CREATE INDEX IF NOT EXISTS idx_spp_rates_academic_year_id ON spp_rates(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_spp_rates_division ON spp_rates(division);
CREATE INDEX IF NOT EXISTS idx_spp_rates_record_status ON spp_rates(record_status);

CREATE INDEX IF NOT EXISTS idx_spp_overrides_student_id ON spp_overrides(student_id);
CREATE INDEX IF NOT EXISTS idx_spp_overrides_record_status ON spp_overrides(record_status);

-- Bills Indexes
CREATE INDEX IF NOT EXISTS idx_bills_student_id ON bills(student_id);
CREATE INDEX IF NOT EXISTS idx_bills_classroom_id ON bills(classroom_id);
CREATE INDEX IF NOT EXISTS idx_bills_academic_year_id ON bills(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_bills_record_status ON bills(record_status);

-- Payments Indexes
CREATE INDEX IF NOT EXISTS idx_payments_bill_id ON payments(bill_id);
CREATE INDEX IF NOT EXISTS idx_payments_student_id ON payments(student_id);
CREATE INDEX IF NOT EXISTS idx_payments_verification_status ON payments(verification_status);
CREATE INDEX IF NOT EXISTS idx_payments_period_id ON payments(period_id);
CREATE INDEX IF NOT EXISTS idx_payments_record_status ON payments(record_status);

-- Expenses Indexes
CREATE INDEX IF NOT EXISTS idx_expenses_division ON expenses(division);
CREATE INDEX IF NOT EXISTS idx_expenses_academic_year_id ON expenses(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_expenses_period_id ON expenses(period_id);
CREATE INDEX IF NOT EXISTS idx_expenses_record_status ON expenses(record_status);

-- Cash Transactions Indexes
CREATE INDEX IF NOT EXISTS idx_cash_transactions_division ON cash_transactions(division);
CREATE INDEX IF NOT EXISTS idx_cash_transactions_period_id ON cash_transactions(period_id);
CREATE INDEX IF NOT EXISTS idx_cash_transactions_reference_id ON cash_transactions(reference_id);
CREATE INDEX IF NOT EXISTS idx_cash_transactions_record_status ON cash_transactions(record_status);

-- Salary Records Indexes
CREATE INDEX IF NOT EXISTS idx_salary_records_teacher_id ON salary_records(teacher_id);
CREATE INDEX IF NOT EXISTS idx_salary_records_division ON salary_records(division);
CREATE INDEX IF NOT EXISTS idx_salary_records_period_id ON salary_records(period_id);
CREATE INDEX IF NOT EXISTS idx_salary_records_record_status ON salary_records(record_status);

-- Activities Indexes
CREATE INDEX IF NOT EXISTS idx_activities_user_id ON activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_division ON activities(division);
CREATE INDEX IF NOT EXISTS idx_activities_entity_id ON activities(entity_id);
CREATE INDEX IF NOT EXISTS idx_activities_record_status ON activities(record_status);

-- Financial Periods & Settings Indexes
CREATE INDEX IF NOT EXISTS idx_financial_periods_record_status ON financial_periods(record_status);
CREATE INDEX IF NOT EXISTS idx_settings_record_status ON settings(record_status);
