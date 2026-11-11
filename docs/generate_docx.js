const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Define the temporary directory structure for OpenXML docx
const tempDir = path.join(__dirname, 'temp_docx');
const relsDir = path.join(tempDir, '_rels');
const wordDir = path.join(tempDir, 'word');
const wordRelsDir = path.join(wordDir, '_rels');

if (fs.existsSync(tempDir)) {
  fs.rmSync(tempDir, { recursive: true, force: true });
}

fs.mkdirSync(tempDir, { recursive: true });
fs.mkdirSync(relsDir, { recursive: true });
fs.mkdirSync(wordDir, { recursive: true });
fs.mkdirSync(wordRelsDir, { recursive: true });

// 1. [Content_Types].xml
const contentTypesXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>`;
fs.writeFileSync(path.join(tempDir, '[Content_Types].xml'), contentTypesXml, 'utf8');

// 2. _rels/.rels
const relsXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>`;
fs.writeFileSync(path.join(relsDir, '.rels'), relsXml, 'utf8');

// 3. word/_rels/document.xml.rels
const wordRelsXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>`;
fs.writeFileSync(path.join(wordRelsDir, 'document.xml.rels'), wordRelsXml, 'utf8');

// 4. word/styles.xml
const stylesXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="21"/>
        <w:szCs w:val="21"/>
        <w:color w:val="2D3748"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
</w:styles>`;
fs.writeFileSync(path.join(wordDir, 'styles.xml'), stylesXml, 'utf8');

// Helper to escape XML
function xmlEscape(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

function p(text, opts = {}) {
  let rPr = '';
  if (opts.bold) rPr += '<w:b/><w:bCs/>';
  if (opts.italic) rPr += '<w:i/><w:iCs/>';
  if (opts.size) rPr += `<w:sz w:val="${opts.size}"/><w:szCs w:val="${opts.size}"/>`;
  if (opts.color) rPr += `<w:color w:val="${opts.color}"/>`;

  let pPr = '';
  let spaceBefore = opts.spaceBefore !== undefined ? opts.spaceBefore : 80;
  let spaceAfter = opts.spaceAfter !== undefined ? opts.spaceAfter : 80;
  let align = opts.align ? `<w:jc w:val="${opts.align}"/>` : '';
  
  pPr = `<w:pPr>${align}<w:spacing w:before="${spaceBefore}" w:after="${spaceAfter}" w:line="260" w:lineRule="auto"/></w:pPr>`;

  return `<w:p>${pPr}<w:r><w:rPr>${rPr}</w:rPr><w:t xml:space="preserve">${xmlEscape(text)}</w:t></w:r></w:p>`;
}

function heading1(text) {
  return p(text, { bold: true, size: 28, color: '1B5E20', spaceBefore: 240, spaceAfter: 80 });
}

function heading2(text) {
  return p(text, { bold: true, size: 23, color: '2E7D32', spaceBefore: 180, spaceAfter: 60 });
}

function bullet(title, text) {
  return `<w:p><w:pPr><w:ind w:left="360" w:hanging="240"/><w:spacing w:before="60" w:after="60" w:line="250" w:lineRule="auto"/></w:pPr><w:r><w:rPr><w:b/><w:color w:val="1B5E20"/></w:rPr><w:t>• </w:t></w:r><w:r><w:rPr><w:b/><w:color w:val="1A202C"/><w:sz w:val="21"/></w:rPr><w:t xml:space="preserve">${xmlEscape(title)}: </w:t></w:r><w:r><w:rPr><w:color w:val="334155"/><w:sz w:val="20.5"/></w:rPr><w:t xml:space="preserve">${xmlEscape(text)}</w:t></w:r></w:p>`;
}

// 5. word/document.xml
const bodyXml = [
  p('TECHNICAL ARTEFACT REPORT', { bold: true, size: 34, color: '1B5E20', align: 'center', spaceBefore: 0, spaceAfter: 40 }),
  p('The Zim Herbal Digital Repository: An Ethnobotanical Knowledge & Ingestion Engine', { bold: true, size: 23, color: '2E7D32', align: 'center', spaceBefore: 0, spaceAfter: 140 }),
  p('Author / Engineering Lead: Desmond Nemadire  |  Platform: Web Application (PWA)  |  Domain: Digital Health & Heritage-Based Ethnobotany', { italic: true, size: 18, color: '64748B', align: 'center', spaceBefore: 0, spaceAfter: 200 }),
  
  heading1('1. System Nature & Vision: An Ethnobotanical Intelligence Engine'),
  p('The Zim Herbal Repository is engineered not simply as a passive electronic catalog, but as an active, high-throughput ethnobotanical intelligence engine. Traditional medicine in Zimbabwe has historically existed as an unstandardized, oral body of knowledge scattered across rural communities and traditional healers. The engine provides an automated data ingestion, validation, and scientific structuring pipeline that converts raw, indigenous oral records into structured, scientifically verified digital health assets compatible with global botanical taxonomies.'),

  heading1('2. Core System Architecture & Functionalities'),
  bullet('Dual-Vernacular Taxonomy Indexer', 'Empowers discovery across national indigenous languages (Shona, Ndebele), English common names, and international botanical classifications (binomial Latin nomenclature, Family, and Growth habit).'),
  bullet('Phytotherapy Safety & Toxicology Protocols', 'Mitigates health hazards by providing explicit contraindications, documented cautions (e.g. pregnancy warnings, toxicity limits, child dosages), and preparation methods for every recorded species.'),
  bullet('14-Column Scientific Bulk Ingestion Pipeline', 'Features an automated Excel (.xlsx) and CSV (.csv) parsing engine with schema validation, enabling research institutions, universities, and rural clinics to ingest hundreds of ethnopharmacological records in seconds.'),
  bullet('Visual Herbarium with Clipboard Ingestion', 'Facilitates fast, ergonomic botanical fieldwork documentation by enabling instant clipboard image pasting (Ctrl + V) and multi-image photo gallery management.'),
  bullet('Audit Attribution & Tri-Tier Governance', 'Enforces strict data integrity with Admin, Ethnobotanical Moderator, and Citizen roles, recording immutable audit stamps (created_by, verified_by, updated_at).'),

  heading1('3. How the Engine Solves Critical National Problems in Zimbabwe'),
  bullet('Permanent Loss of Indigenous Knowledge Systems (IKS)', 'Over 80% of Zimbabwe’s indigenous healing heritage is held by an aging elder generation without written preservation. The engine acts as a permanent national digital vault.'),
  bullet('High Healthcare Costs & Pharmaceutical Shortages', 'With over 70% of Zimbabweans relying on primary traditional phytotherapy due to prohibitive imported drug costs, the engine standardizes local herbal alternatives for primary community healthcare.'),
  bullet('Accidental Plant Poisoning & Misidentification', 'Traditional plant consumption has historically suffered from fatal misidentifications and unregulated dosages. The engine acts as a scientific safety barrier through clear dosage and toxicity documentation.'),
  bullet('Strategic National Policy Alignment', 'Directly advances Heritage-Based Education 5.0, National Development Strategy 1 (NDS1), Vision 2030, and the POTRAZ Universal Service Fund mandate by delivering lightweight, low-bandwidth health intelligence to marginalized rural communities.')
].join('');

const documentXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    ${bodyXml}
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1000" w:right="1000" w:bottom="1000" w:left="1000" w:header="720" w:footer="720" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>`;

fs.writeFileSync(path.join(wordDir, 'document.xml'), documentXml, 'utf8');

// Create docx via PowerShell Compress-Archive
const outputDocx = path.join(__dirname, 'Zim_Herbal_Repository_Technical_Report.docx');
if (fs.existsSync(outputDocx)) {
  fs.unlinkSync(outputDocx);
}

const tempZip = path.join(__dirname, 'temp_archive.zip');
if (fs.existsSync(tempZip)) {
  fs.unlinkSync(tempZip);
}

try {
  execSync(`powershell -Command "$ProgressPreference = 'SilentlyContinue'; Compress-Archive -Path '${tempDir}\\*' -DestinationPath '${tempZip}' -Force"`, { stdio: 'inherit' });
  fs.renameSync(tempZip, outputDocx);
  fs.rmSync(tempDir, { recursive: true, force: true });
  console.log('SUCCESS: Generated DOCX at ' + outputDocx);
} catch (err) {
  console.error('Error creating docx:', err);
  process.exit(1);
}
