ALTER TABLE classrooms ADD COLUMN homeroom_teacher_id TEXT REFERENCES teachers(id) ON DELETE SET NULL;
