/**
 * Synthetic copy of the assistant project's mock-fap-v2 fixture (apps/fap_fixture): same IDs,
 * column order and radio naming as the reference lecturer page, with synthetic students only.
 */
export const roster = Array.from({ length: 40 }, (_, index) => ({
  studentCode: `SE18${String(index + 1).padStart(4, '0')}`,
  fullName: `Demo Student ${String(index + 1).padStart(2, '0')}`,
}));

export const SESSION_ID = '80000000-0000-4000-8000-000000000001';

const PAGE = `
<div id="ctl00_lblCampusName">FU-HL</div>
<div id="ctl00_mainContent_divTitle"><p>Attendance for <b>Lecturer Demo</b> at slot 2 on Friday 18/09/2026 at room NVH 611.This is the session number 1 of the course.</p></div>
<form id="aspnetForm">
  <table id="ctl00_mainContent_gvAttendance" data-layout-version="mock-fap-v2" data-course="SWE201c" data-session-id="${SESSION_ID}">
    <thead><tr><th></th><th>Group</th><th>Roll Number</th><th>Full Name</th><th>ABSENT</th><th>PRESENT</th><th>...</th><th>COMMENT</th><th>SHOW IMAGE</th><th></th></tr></thead>
    <tbody id="attendance-rows"></tbody>
  </table>
  <span id="save-status"></span>
  <input id="ctl00_mainContent_btnSave" name="ctl00$mainContent$btnSave" type="submit" value="Save" />
</form>`;

function createRow(doc: Document, student: (typeof roster)[number], index: number) {
  const prefix = `ctl00_mainContent_gvAttendance_ctl${String(index + 2).padStart(2, '0')}`;
  const row = doc.createElement('tr');
  const cells = Array.from({ length: 10 }, () => row.insertCell());
  cells[0]!.textContent = String(index + 1);
  const spans: [number, string, string][] = [
    [1, 'txtGroupName', 'SE1927'],
    [2, 'txtRollNumber', student.studentCode],
    [3, 'txtFullName', student.fullName],
  ];
  for (const [column, suffix, text] of spans) {
    const span = doc.createElement('span');
    span.id = `${prefix}_${suffix}`;
    span.textContent = text;
    cells[column]!.append(span);
  }
  const radios: [number, string][] = [
    [4, 'rdAbsent'],
    [5, 'rdPresent'],
  ];
  for (const [column, suffix] of radios) {
    const input = doc.createElement('input');
    input.type = 'radio';
    input.id = `${prefix}_${suffix}`;
    input.name = `${prefix.replaceAll('_', '$')}$chkCheck`;
    input.value = suffix;
    input.checked = suffix === 'rdAbsent';
    cells[column]!.append(input);
  }
  const comment = doc.createElement('input');
  comment.type = 'text';
  comment.id = `${prefix}_txtComment`;
  cells[7]!.append(comment);
  return row;
}

export function installFixture(doc: Document, { local = false } = {}) {
  doc.body.innerHTML = PAGE;
  if (local) delete doc.body.dataset.fapFixture;
  else doc.body.dataset.fapFixture = 'mock-fap-v2';
  const tbody = doc.querySelector('#attendance-rows')!;
  roster.forEach((student, index) => tbody.append(createRow(doc, student, index)));
}
