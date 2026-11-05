// Synthetic values only. The IDs, names and column order mirror the supplied reference.
export function createAttendanceRow(document, student, index) {
  const prefix = `ctl00_mainContent_gvAttendance_ctl${String(index + 2).padStart(2, '0')}`;
  const row = document.createElement('tr');
  const cells = Array.from({ length: 10 }, () => row.insertCell());
  cells[0].textContent = String(index + 1);
  for (const [column, suffix, text] of [[1, 'txtGroupName', student.group], [2, 'txtRollNumber', student.studentCode], [3, 'txtFullName', student.fullName]]) {
    const span = document.createElement('span');
    span.id = `${prefix}_${suffix}`;
    span.textContent = text;
    cells[column].append(span);
  }
  for (const [column, suffix, labelText] of [[4, 'rdAbsent', 'Absent'], [5, 'rdPresent', 'Present']]) {
    const input = document.createElement('input');
    input.type = 'radio'; input.id = `${prefix}_${suffix}`; input.name = `${prefix.replaceAll('_', '$')}$chkCheck`;
    input.value = suffix; input.checked = suffix === 'rdAbsent';
    const label = document.createElement('label'); label.htmlFor = input.id; label.textContent = labelText;
    cells[column].append(input, label);
  }
  const online = document.createElement('span'); online.id = `${prefix}_txtOnline`; online.textContent = 'Offline'; cells[6].append(online);
  const comment = document.createElement('input'); comment.type = 'text'; comment.id = `${prefix}_txtComment`;
  comment.name = `${prefix.replaceAll('_', '$')}$txtComment`; comment.maxLength = 120; comment.setAttribute('aria-label', `Comment for ${student.studentCode}`); cells[7].append(comment);
  const avatar = document.createElement('span'); avatar.className = 'student-avatar'; avatar.textContent = 'DEMO'; cells[8].append(avatar);
  return row;
}
