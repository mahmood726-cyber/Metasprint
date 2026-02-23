$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$exclude = @('index.html', 'generate_index.ps1')
$files = Get-ChildItem -Path $root -File | Where-Object { $exclude -notcontains $_.Name }

$htmlTitles = @{
  'meta-sprint-animal-v1.html' = 'Meta-sprint: Animal'
  'meta-sprint-dose-v1.html' = 'Meta-sprint: Dose'
  'meta-sprint-dta-v1.html' = 'Meta-sprint: Diagnostic Test Accuracy'
  'meta-sprint-hta-v1.html' = 'Meta-sprint: Health Technology Assessment'
  'meta-sprint-ipd-v1.html' = 'Meta-sprint: IPD'
  'meta-sprint-living-v1.html' = 'Meta-sprint: Living Reviews'
  'meta-sprint-nma-v3.html' = 'Meta-sprint: Network Meta-Analysis'
  'meta-sprint-prev-v1.html' = 'Meta-sprint: Prevalence'
  'meta-sprint-prog-v1.html' = 'Meta-sprint: Prognostic Reviews'
  'meta-sprint-qes-v1.html' = 'Meta-sprint: Qualitative Evidence Synthesis'
  'meta-sprint-rapid-v1.html' = 'Meta-sprint: Rapid Reviews'
  'meta-sprint-surv-v1.html' = 'Meta-sprint: Survival'
  'meta-sprint-umbrella-v1.html' = 'Meta-sprint: Umbrella Reviews'
  'meta-sprint-v3_0-2.html' = 'Meta-sprint v3.0-2'
}

$supportTitles = @{
  'compare_methods.py' = 'Compare Methods'
  'debug_test.py' = 'Debug Test'
  'test_metasprint.py' = 'Meta-sprint Tests'
  'MAJOR_IMPROVEMENTS.md' = 'Major Improvements'
  'spec_compliance_check.md' = 'Spec Compliance Check'
  'metasprint_comparison.png' = 'Meta-sprint Comparison'
}

function Escape-Html([string]$text) {
  return [System.Security.SecurityElement]::Escape($text)
}

function To-Title([string]$name) {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($name)
  $base = $base -replace '[_-]+', ' '
  return (Get-Culture).TextInfo.ToTitleCase($base)
}

$htmlPriority = @('meta-sprint-v3_0-2.html', 'meta-sprint-nma-v3.html')
$htmlPriorityMap = @{}
for ($i = 0; $i -lt $htmlPriority.Count; $i++) {
  $htmlPriorityMap[$htmlPriority[$i]] = $i
}

$htmlFiles = $files | Where-Object { $_.Extension -eq '.html' } | Sort-Object `
  @{ Expression = { if ($htmlPriorityMap.ContainsKey($_.Name)) { $htmlPriorityMap[$_.Name] } else { 999 } } }, `
  @{ Expression = { $_.Name } }
$otherFiles = $files | Where-Object { $_.Extension -ne '.html' } | Sort-Object Name

$types = $files | ForEach-Object {
  $ext = $_.Extension.TrimStart('.').ToLowerInvariant()
  if ($ext) { $ext } else { 'file' }
} | Sort-Object -Unique
$orderedTypes = @()
if ($types -contains 'html') {
  $orderedTypes += 'html'
  $types = $types | Where-Object { $_ -ne 'html' }
}
$orderedTypes += $types

$htmlCards = @()
foreach ($f in $htmlFiles) {
  $name = $f.Name
  $title = $htmlTitles[$name]
  if (-not $title) {
    if ($name -like 'meta-sprint-*') {
      $title = 'Meta-sprint: ' + (To-Title $name).Replace('Meta Sprint ', '')
    } else {
      $title = To-Title $name
    }
  }
  $safeName = Escape-Html $name
  $safeTitle = Escape-Html $title

  $primaryTag = ''
  if ($htmlPriorityMap.ContainsKey($name)) {
    $primaryTag = '<span class="tag tag-primary">Primary</span>'
  }

  $htmlCards += '        <a href="' + $safeName + '" class="course-card" data-type="html" data-name="' + $safeName + '" target="_blank" rel="noopener">' 
  $htmlCards += '          <div class="tag-row"><span class="tag tag-html">HTML</span><span class="tag tag-meta">Meta-sprint</span>' + $primaryTag + '</div>'
  $htmlCards += '          <span class="title">' + $safeTitle + '</span>'
  $htmlCards += '          <span class="file">' + $safeName + '</span>'
  $htmlCards += '        </a>'
}

$tagClassMap = @{
  '.md' = 'tag-md'
  '.py' = 'tag-py'
  '.png' = 'tag-png'
}

$supportCards = @()
foreach ($f in $otherFiles) {
  $name = $f.Name
  $title = $supportTitles[$name]
  if (-not $title) {
    $title = To-Title $name
  }
  $ext = $f.Extension.ToLowerInvariant()
  $tagClass = $tagClassMap[$ext]
  if (-not $tagClass) { $tagClass = 'tag-meta' }
  $tagLabel = $ext.TrimStart('.').ToUpperInvariant()
  if ([string]::IsNullOrWhiteSpace($tagLabel)) { $tagLabel = 'FILE' }

  $safeName = Escape-Html $name
  $safeTitle = Escape-Html $title

  $typeValue = $ext.TrimStart('.')
  if ([string]::IsNullOrWhiteSpace($typeValue)) { $typeValue = 'file' }

  $supportCards += '        <a href="' + $safeName + '" class="course-card" data-type="' + $typeValue + '" data-name="' + $safeName + '" target="_blank" rel="noopener">' 
  $supportCards += '          <div class="tag-row"><span class="tag ' + $tagClass + '">' + $tagLabel + '</span></div>'
  $supportCards += '          <span class="title">' + $safeTitle + '</span>'
  $supportCards += '          <span class="file">' + $safeName + '</span>'
  $supportCards += '        </a>'
}

$filterButtons = @()
$filterButtons += '    <button class="filter-tab active" data-type="all" type="button" aria-pressed="true">All</button>'
foreach ($type in $orderedTypes) {
  $label = $type.ToUpperInvariant()
  $filterButtons += '    <button class="filter-tab" data-type="' + $type + '" type="button" aria-pressed="false">' + $label + '</button>'
}

$template = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Meta-sprint Gateway</title>
  <style>
    :root {
      --bg: #0f172a;
      --card-bg: #1e293b;
      --accent: #38bdf8;
      --accent-hover: #7dd3fc;
      --text: #e2e8f0;
      --text-muted: #94a3b8;
      --border: #334155;
      --green: #4ade80;
      --amber: #fbbf24;
    }

    * { margin: 0; padding: 0; box-sizing: border-box; }

    body {
      font-family: "Segoe UI", system-ui, -apple-system, sans-serif;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
    }

    header {
      text-align: center;
      padding: 3rem 1rem 2rem;
      background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
      border-bottom: 1px solid var(--border);
    }

    header h1 {
      font-size: 2.2rem;
      font-weight: 700;
      margin-bottom: 0.5rem;
      background: linear-gradient(90deg, var(--accent), var(--green));
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    header p {
      color: var(--text-muted);
      font-size: 1.1rem;
      max-width: 640px;
      margin: 0 auto;
    }

    .stats {
      display: flex;
      justify-content: center;
      gap: 2rem;
      margin-top: 1.5rem;
      flex-wrap: wrap;
    }

    .stat { text-align: center; }

    .stat-number {
      font-size: 2rem;
      font-weight: 700;
      color: var(--accent);
    }

    .stat-label {
      font-size: 0.85rem;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    .notice {
      margin-top: 0.75rem;
      color: var(--text-muted);
      font-size: 0.95rem;
    }

    .search-bar {
      max-width: 520px;
      margin: 2rem auto 0;
      position: relative;
    }

    .search-bar input {
      width: 100%;
      padding: 0.75rem 1rem 0.75rem 2.5rem;
      border-radius: 8px;
      border: 1px solid var(--border);
      background: var(--card-bg);
      color: var(--text);
      font-size: 1rem;
      outline: none;
      transition: border-color 0.2s;
    }

    .search-bar input:focus {
      border-color: var(--accent);
    }

    .search-bar::before {
      content: "\1F50D";
      position: absolute;
      left: 0.75rem;
      top: 50%;
      transform: translateY(-50%);
      font-size: 1rem;
    }

    .filter-tabs {
      display: flex;
      justify-content: center;
      gap: 0.5rem;
      margin: 1.5rem auto;
      flex-wrap: wrap;
      max-width: 900px;
      padding: 0 1rem;
    }

    .filter-tab {
      padding: 0.4rem 1rem;
      border-radius: 20px;
      border: 1px solid var(--border);
      background: transparent;
      color: var(--text-muted);
      cursor: pointer;
      font-size: 0.85rem;
      transition: all 0.2s;
    }

    .filter-tab:hover,
    .filter-tab.active {
      background: var(--accent);
      color: var(--bg);
      border-color: var(--accent);
    }

    .filter-tab:focus-visible,
    .course-card:focus-visible,
    .search-bar input:focus-visible {
      outline: 2px solid var(--accent);
      outline-offset: 2px;
    }

    main {
      max-width: 1100px;
      margin: 0 auto;
      padding: 1.5rem;
    }

    .section-title {
      font-size: 1.3rem;
      font-weight: 600;
      margin: 2rem 0 1rem;
      padding-bottom: 0.5rem;
      border-bottom: 1px solid var(--border);
      color: var(--accent);
    }

    .section-hint {
      margin: -0.5rem 0 1rem;
      color: var(--text-muted);
      font-size: 0.9rem;
    }

    .course-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
      gap: 1rem;
    }

    .course-card {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 1.25rem;
      transition: all 0.25s;
      text-decoration: none;
      color: inherit;
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
    }

    .course-card:hover {
      border-color: var(--accent);
      transform: translateY(-2px);
      box-shadow: 0 4px 20px rgba(56, 189, 248, 0.15);
    }

    .tag-row {
      display: flex;
      flex-wrap: wrap;
      gap: 0.35rem;
    }

    .course-card .title {
      font-size: 1.05rem;
      font-weight: 600;
      color: var(--text);
      line-height: 1.3;
    }

    .course-card .file {
      font-size: 0.78rem;
      color: var(--text-muted);
      font-family: "Cascadia Code", "Fira Code", monospace;
    }

    .tag {
      display: inline-block;
      padding: 0.15rem 0.6rem;
      border-radius: 12px;
      font-size: 0.72rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      width: fit-content;
    }

    .tag-html { background: #164e63; color: #67e8f9; }
    .tag-md { background: #4c1d95; color: #c4b5fd; }
    .tag-py { background: #14532d; color: #86efac; }
    .tag-png { background: #78350f; color: #fcd34d; }
    .tag-meta { background: #1e3a5f; color: #93c5fd; }
    .tag-primary { background: #0c4a6e; color: #e0f2fe; }

    footer {
      text-align: center;
      padding: 2rem;
      color: var(--text-muted);
      font-size: 0.85rem;
      border-top: 1px solid var(--border);
      margin-top: 3rem;
    }

    footer code {
      font-family: "Cascadia Code", "Fira Code", monospace;
      color: var(--accent);
    }

    .hidden { display: none !important; }

    .sr-only {
      position: absolute;
      width: 1px;
      height: 1px;
      padding: 0;
      margin: -1px;
      overflow: hidden;
      clip: rect(0, 0, 0, 0);
      white-space: nowrap;
      border: 0;
    }

    .empty-state {
      margin: 2rem auto 0;
      max-width: 700px;
      text-align: center;
      padding: 1.25rem;
      border: 1px dashed var(--border);
      border-radius: 12px;
      color: var(--text-muted);
      background: rgba(30, 41, 59, 0.6);
    }

    @media (max-width: 600px) {
      header h1 { font-size: 1.6rem; }
      .course-grid { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <header>
    <h1>Meta-sprint Gateway</h1>
    <p>Meta-sprint collection with quick access to all HTML pages and supporting files.</p>
    <div class="stats">
      <div class="stat">
        <div class="stat-number" id="total-count">0</div>
        <div class="stat-label">Files</div>
      </div>
      <div class="stat">
        <div class="stat-number" id="html-count">0</div>
        <div class="stat-label">HTML (visible/total)</div>
      </div>
      <div class="stat">
        <div class="stat-number" id="support-count">0</div>
        <div class="stat-label">Supporting (visible/total)</div>
      </div>
      <div class="stat">
        <div class="stat-number" id="visible-count">0</div>
        <div class="stat-label">Visible</div>
      </div>
    </div>
    <p class="notice hidden" id="popup-hint">If links open in a tab, allow pop-ups for this file to force a separate window.</p>
    <div id="live-summary" class="sr-only" aria-live="polite"></div>
    <div class="search-bar">
      <input type="text" id="search" placeholder="Search files..." autocomplete="off" aria-label="Search files">
    </div>
  </header>

  <div class="filter-tabs" role="group" aria-label="Filter files by type">
[[FILTER_BUTTONS]]
  </div>

  <main>
    <section data-section>
      <h2 class="section-title">Meta-sprint HTML Pages</h2>
      <p class="section-hint">Primary = main workflows.</p>
      <div class="course-grid" data-grid>
[[HTML_CARDS]]
      </div>
    </section>

    <section data-section>
      <h2 class="section-title">Supporting Files</h2>
      <div class="course-grid" data-grid>
[[SUPPORT_CARDS]]
      </div>
    </section>
  </main>

  <div class="empty-state hidden" id="empty-state">No files match your search or filter.</div>

  <footer>Meta-sprint gateway index.html — Run <code>generate_index.ps1</code> to refresh.</footer>

  <script>
    const searchInput = document.getElementById('search');
    const cards = document.querySelectorAll('.course-card');
    const grids = document.querySelectorAll('[data-grid]');
    const tabs = document.querySelectorAll('.filter-tab');
    const emptyState = document.getElementById('empty-state');
    const liveSummary = document.getElementById('live-summary');
    const popupHint = document.getElementById('popup-hint');

    const totalCount = document.getElementById('total-count');
    const htmlCount = document.getElementById('html-count');
    const supportCount = document.getElementById('support-count');
    const visibleCount = document.getElementById('visible-count');

    let activeType = 'all';
    const total = cards.length;
    const totalHtml = document.querySelectorAll('.course-card[data-type="html"]').length;
    const totalSupport = total - totalHtml;

    totalCount.textContent = total;

    function applyFilter() {
      const q = searchInput.value.trim().toLowerCase();
      let visible = 0;
      let visibleHtml = 0;
      let visibleSupport = 0;

      cards.forEach(card => {
        const type = card.dataset.type;
        const text = card.textContent.toLowerCase();
        const typeMatch = activeType === 'all' || type === activeType;
        const queryMatch = q === '' || text.includes(q);
        const show = typeMatch && queryMatch;
        card.classList.toggle('hidden', !show);
        if (show) {
          visible += 1;
          if (type === 'html') {
            visibleHtml += 1;
          } else {
            visibleSupport += 1;
          }
        }
      });

      visibleCount.textContent = visible;
      htmlCount.textContent = visibleHtml + ' / ' + totalHtml;
      supportCount.textContent = visibleSupport + ' / ' + totalSupport;
      liveSummary.textContent = visible + ' results shown. ' + visibleHtml + ' HTML, ' + visibleSupport + ' supporting.';

      grids.forEach(grid => {
        const gridVisible = grid.querySelectorAll('.course-card:not(.hidden)').length;
        const section = grid.closest('[data-section]');
        if (section) {
          section.classList.toggle('hidden', gridVisible === 0);
        }
      });

      emptyState.classList.toggle('hidden', visible !== 0);
    }

    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        tabs.forEach(t => {
          t.classList.remove('active');
          t.setAttribute('aria-pressed', 'false');
        });
        tab.classList.add('active');
        tab.setAttribute('aria-pressed', 'true');
        activeType = tab.dataset.type;
        applyFilter();
      });
    });

    searchInput.addEventListener('input', applyFilter);

    document.querySelectorAll('.course-card').forEach(card => {
      card.addEventListener('click', (event) => {
        if (event.defaultPrevented) return;
        if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
        const opened = window.open(card.href, '_blank', 'noopener,noreferrer,width=1200,height=800');
        if (opened) {
          event.preventDefault();
        } else if (popupHint) {
          popupHint.classList.remove('hidden');
        }
      });
    });

    applyFilter();
  </script>
</body>
</html>
"@

$htmlBlock = $htmlCards -join "`n"
$supportBlock = $supportCards -join "`n"
$filterBlock = $filterButtons -join "`n"

$output = $template.Replace('[[HTML_CARDS]]', $htmlBlock).Replace('[[SUPPORT_CARDS]]', $supportBlock).Replace('[[FILTER_BUTTONS]]', $filterBlock)

Set-Content -Path (Join-Path $root 'index.html') -Value $output -Encoding UTF8

"Generated index.html"
