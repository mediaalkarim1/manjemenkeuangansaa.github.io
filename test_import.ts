import fs from 'fs';
import { BackupService } from './src/lib/backup-service';

const rawJson = fs.readFileSync('/Users/syien/Downloads/saa-finance-backup-v2.1.0-2026-08-06-2.json', 'utf8');
const validationResult = BackupService.validateBackup(rawJson);

console.log('Validation Is Valid:', validationResult.isValid);
if (validationResult.payload) {
  console.log('Validation Classrooms Count:', validationResult.payload.classrooms?.length);
  
  const restored = BackupService.applyRestore(
    validationResult.payload,
    'replace',
    [],
    [],
    [],
    []
  );
  
  console.log('Restored Classrooms Count:', restored.classrooms.length);
  const orphanCount = restored.students.filter(s => 
    !restored.classrooms.find(c => c.id === s.classroomId)
  ).length;
  console.log('Orphaned Students (Classroom not found):', orphanCount);
} else {
  console.log('No payload in validationResult');
}
