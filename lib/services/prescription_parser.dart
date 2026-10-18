// lib/services/prescription_parser.dart
//
// 1. Decides whether OCR text is a prescription (Rx symbol + supporting markers)
// 2. Extracts patient / doctor / medication info
// 3. Translates doctor shorthand (PO, qhs, bid, prn ...) into plain language
// 4. Handles printed prescription-pad layouts (BRAND / strength line / generic line)

class ParsedMedication {
  final String name;
  final String? strength; // e.g. "300 mg / 250 mg tablet"
  final String howToTake; // plain-language instruction
  final String rawInstruction; // exactly what the doctor wrote
  final String? quantity; // plain language, e.g. "30 in total"
  final String? refills; // plain language, e.g. "No refills"

  const ParsedMedication({
    required this.name,
    this.strength,
    required this.howToTake,
    required this.rawInstruction,
    this.quantity,
    this.refills,
  });
}

class ParsedPrescription {
  final String? patientName;
  final String? dateOfBirth;
  final String? age;
  final String? date;
  final String? doctorName;
  final String? doctorLicense;
  final List<ParsedMedication> medications;
  final String rawText;

  const ParsedPrescription({
    this.patientName,
    this.dateOfBirth,
    this.age,
    this.date,
    this.doctorName,
    this.doctorLicense,
    required this.medications,
    required this.rawText,
  });
}

class PrescriptionParser {
  // ---------------------------------------------------------------- detection

  // Accepts ℞, Rx, Bx, Px, "R x", Rx glued to a word, or a lone "R" line
  static final _rxSymbol = RegExp(
    r'℞|(?<![A-Za-z])[RBP]\s?[xX](?![a-z])|^\s*R\s*[/.]?\s*$',
    multiLine: true,
  );

  static final _strength = RegExp(
    r'(\d+(?:[.,]\d+)?)\s?(mcg|mg|ml|g|iu|units?|%)(?![a-z])',
    caseSensitive: false,
  );

  /// Supporting markers that appear on real prescriptions.
  static final List<RegExp> _markers = [
    RegExp(r'patient|\bname\b', caseSensitive: false),
    RegExp(r'\bdob\b|date of birth|\bage\b', caseSensitive: false),
    RegExp(r'\bdate\b', caseSensitive: false),
    RegExp(r'\bdisp(?:ense)?\b|\bsig\b|directions', caseSensitive: false),
    RegExp(r'refill', caseSensitive: false),
    RegExp(r'signature|\bm\.?d\.?\b|\bdr\.?\s|licen[sc]e|\bprc\b|\bptr\b',
        caseSensitive: false),
    RegExp(r'\b(po|qd|bid|tid|qid|qhs|ghs|prn|q\d+h)\b', caseSensitive: false),
    _strength,
  ];

  /// A document is a prescription if:
  ///  - the Rx symbol was read AND at least 2 supporting markers are present, OR
  ///  - the Rx symbol was NOT read (OCR often misses the stylized glyph) but
  ///    at least 5 distinct prescription markers are present.
  static bool isPrescription(String text) {
    if (text.trim().length < 15) return false;
    final hits = _markers.where((m) => m.hasMatch(text)).length;
    final hasRx = _rxSymbol.hasMatch(text);
    return hasRx ? hits >= 2 : hits >= 5;
  }

  // ------------------------------------------------------------------ parsing

  /// Returns null when the text is not a prescription (show nothing).
  static ParsedPrescription? parse(String text) {
    if (!isPrescription(text)) return null;

    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    const dateRe =
        r'(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}|[A-Za-z]{3,9}\.? \d{1,2},? \d{4})';

    String? find(RegExp re) {
      for (final l in lines) {
        final m = re.firstMatch(l);
        if (m != null && m.groupCount >= 1 && m.group(1) != null) {
          return m.group(1)!.trim();
        }
      }
      return null;
    }

    var patient = find(RegExp(
        r"(?:patient\s*name|patient|name)\s*[:\-]?\s*([A-Za-z][A-Za-z.,' \-]{2,}?)(?=\s*(?:dob|age|date|address|$))",
        caseSensitive: false));
    final dob = find(RegExp(
        r'(?:dob|date of birth|birth\s*date)\s*[:\-]?\s*' + dateRe,
        caseSensitive: false));
    final age =
        find(RegExp(r'\bage\s*[:\-]?\s*(\d{1,3})', caseSensitive: false));
    final date =
        find(RegExp(r'\bdate\s*[:\-]?\s*' + dateRe, caseSensitive: false));

    // Doctor: a whole line ending in "M.D." (e.g. "JOHNATHAN H, SIMON, M.D."),
    // otherwise a "Dr. Name" pattern.
    final doctor = find(RegExp(r'^(.{3,60}?,?\s*M\.?D\.?)[\s,.]*$',
            caseSensitive: false)) ??
        find(RegExp(r"(\bdr\.?\s+[A-Za-z.' \-]+)", caseSensitive: false));

    final license = find(RegExp(
        r'(?:licen[sc]e|prc|ptr|s2)\s*(?:no\.?|#)?\s*[:#]?\s*([A-Z0-9\-]{4,})',
        caseSensitive: false));

    if (patient != null) patient = patient.replaceAll(RegExp(r'[,.\s]+$'), '');

    // ---- medications (handwritten-style lines: "Colace 100mg 1 tab PO qhs") ----
    final meds = <_MedBuilder>[];
    _MedBuilder? current;

    final skipLine = RegExp(
        r'^(?:patient|name|dob|date|address|signature|sig\b|directions|licen)',
        caseSensitive: false);
    final dispRe = RegExp(r'\bdisp(?:ense)?\.?\s*[:#]?\s*#?\s*(\d+)',
        caseSensitive: false);
    final refillRe = RegExp(
        r'refills?\s*[:\-]?\s*(\d+|[φØø⌀]|none|nil|o\b)',
        caseSensitive: false);

    for (final line in lines) {
      final disp = dispRe.firstMatch(line);
      if (disp != null) {
        current?.quantity = disp.group(1);
        continue;
      }
      final ref = refillRe.firstMatch(line);
      if (ref != null) {
        current?.refills = ref.group(1);
        continue;
      }
      if (skipLine.hasMatch(line) ||
          (_rxSymbol.hasMatch(line) && line.length < 4)) {
        continue;
      }

      final s = _strength.firstMatch(line);
      if (s != null) {
        final name = line
            .substring(0, s.start)
            .replaceAll(
                RegExp(r'^(?:℞|[RBP]\s?[xX]\.?)\s*', caseSensitive: false), '')
            .replaceAll(RegExp(r'[^A-Za-z\- ]'), '')
            .trim();
        if (name.isNotEmpty) {
          current =
              _MedBuilder(name, '${s.group(1)} ${s.group(2)!.toLowerCase()}');
          current.instruction.write(line.substring(s.end));
          meds.add(current);
          continue;
        }
      }
      // Continuation of the current medication's directions
      if (current != null && SigTranslator.looksLikeSig(line)) {
        current.instruction.write(' $line');
      }
    }

    // If no "Name 100mg ..." lines were found, try the printed-pad layout
    final medications = meds.isNotEmpty
        ? meds.map((m) => m.build()).toList()
        : _padMedications(lines);

    return ParsedPrescription(
      patientName: patient,
      dateOfBirth: dob,
      age: age,
      date: date,
      doctorName: doctor,
      doctorLicense: license,
      rawText: text,
      medications: medications,
    );
  }

  // ------------------------------------------------- printed prescription pads
  //
  // Many pads print medicines like this (OCR returns them as separate lines):
  //     LAGAFLEX                          <- brand (ALL CAPS, one word)
  //     300mg/250mg Tablet                <- strength + form
  //     Carisoprodol + Paracetamol        <- generic name(s)
  static List<ParsedMedication> _padMedications(List<String> lines) {
    final brandRe = RegExp(r'^[A-Z][A-Z0-9\-]{4,}$');
    const notBrand = {
      'PATIENT', 'ADDRESS', 'SIGNATURE', 'CLINIC', 'HOSPITAL',
      'LABORATORY', 'MEDICINE', 'SCHEDULE', 'APPOINTMENT',
    };
    final strengthLine = RegExp(
      r'^\s*(\d+(?:[.,]\d+)?\s?(?:mcg|mg|g|ml|iu)(?:\s?/\s?[\dil.]*\s?(?:mcg|mg|g|ml|iu)?)?)\s*(.*)$',
      caseSensitive: false,
    );

    final brands = <String>[];
    final strengths = <String>[];
    final genericLines = <String>[];

    for (final line in lines) {
      if (brandRe.hasMatch(line) && !notBrand.contains(line)) {
        brands.add(line);
        continue;
      }
      final s = strengthLine.firstMatch(line);
      if (s != null) {
        final form = _formOf(s.group(2) ?? '');
        strengths.add('${_formatStrength(s.group(1)!)}${form != null ? ' $form' : ''}');
        continue;
      }
      if (line.contains('+') || (!line.contains(':') && _hasKnownGeneric(line))) {
        genericLines.add(line);
      }
    }

    if (strengths.isEmpty) return [];

    final groups = _groupGenerics(genericLines.join(' '));
    final result = <ParsedMedication>[];

    for (var i = 0; i < strengths.length; i++) {
      final brand = i < brands.length ? _capitalize(brands[i]) : null;
      final generic = i < groups.length ? groups[i].join(' + ') : null;

      String name;
      if (brand != null && generic != null) {
        name = '$brand ($generic)';
      } else {
        name = brand ?? generic ?? 'Medicine ${i + 1}';
      }

      result.add(ParsedMedication(
        name: name,
        strength: strengths[i],
        rawInstruction: '',
        howToTake:
            'The directions (how much, how often) could not be read in the scan, they may be handwritten. Please ask your doctor or pharmacist.',
      ));
    }
    return result;
  }

  static String _formatStrength(String s) {
    var t = s
        .toLowerCase()
        // OCR often reads "1" as "i" or "l" after the slash: "50 mg/i g"
        .replaceAll(RegExp(r'/\s*[il]\s*(?=mcg|mg|g\b|ml|iu)'), '/1');
    t = t.replaceAllMapped(
        RegExp(r'(\d)\s*(mcg|mg|ml|iu|g)\b'), (m) => '${m[1]} ${m[2]}');
    return t.replaceAll(RegExp(r'\s*/\s*'), ' / ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String? _formOf(String rest) {
    final l = rest.toLowerCase();
    final film = l.contains('coat') || l.contains('flm') || l.contains('film');
    String? kind;
    if (l.contains('tab')) {
      kind = 'tablet';
    } else if (l.contains('cap')) {
      kind = 'capsule';
    } else if (l.contains('syr')) {
      kind = 'syrup';
    } else if (l.contains('susp')) {
      kind = 'suspension';
    }
    if (kind == null) return null;
    return (film && kind == 'tablet') ? 'film-coated tablet' : kind;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  // Groups a generic-name line into one list per medicine.
  // A "+" joins ingredients of the same medicine; two names with no "+"
  // between them belong to different medicines.
  static List<List<String>> _groupGenerics(String raw) {
    const salts = {
      'hcl', 'hydrochloride', 'sodium', 'potassium', 'besylate', 'maleate',
      'sulfate', 'mesylate', 'tartrate', 'succinate', 'calcium', 'magnesium',
    };
    final tokens = raw
        .replaceAll('+', ' + ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty);

    final groups = <List<String>>[];
    var joinNext = false;

    for (final t in tokens) {
      if (t == '+') {
        joinNext = true;
        continue;
      }
      final low = t.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (salts.contains(low) && groups.isNotEmpty) {
        groups.last[groups.last.length - 1] +=
            ' ${low == 'hcl' ? 'HCl' : _capitalize(low)}';
        continue;
      }
      final match = _closestGeneric(t);
      final name = match != null ? _capitalize(match) : _capitalize(t);
      if (groups.isEmpty || !joinNext) {
        groups.add([name]);
      } else {
        groups.last.add(name);
      }
      joinNext = false;
    }
    return groups;
  }

  static bool _hasKnownGeneric(String line) {
    final words = line.split(RegExp(r'\s+'));
    if (words.length > 4) return false;
    return words.any((w) => _closestGeneric(w) != null);
  }

  // Corrects small OCR typos (e.g. "Carlsoprodol" -> carisoprodol) by matching
  // against a list of common generic names. Short names must match nearly
  // exactly, so unrelated words are not changed.
  static String? _closestGeneric(String token) {
    final t = token.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (t.length < 5) return null;
    final limit = t.length >= 7 ? 2 : 1;
    String? best;
    var bestD = limit + 1;
    for (final g in _generics) {
      if ((g.length - t.length).abs() > limit) continue;
      final d = _levenshtein(t, g);
      if (d < bestD) {
        bestD = d;
        best = g;
      }
    }
    return best;
  }

  static int _levenshtein(String a, String b) {
    var prev = List<int>.generate(b.length + 1, (j) => j);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0);
      cur[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        var v = prev[j] + 1;
        if (cur[j - 1] + 1 < v) v = cur[j - 1] + 1;
        if (prev[j - 1] + cost < v) v = prev[j - 1] + cost;
        cur[j] = v;
      }
      prev = cur;
    }
    return prev[b.length];
  }

  static const _generics = <String>[
    'paracetamol', 'acetaminophen', 'ibuprofen', 'naproxen', 'diclofenac',
    'celecoxib', 'etoricoxib', 'carisoprodol', 'orphenadrine', 'tramadol',
    'metformin', 'sitagliptin', 'vildagliptin', 'linagliptin', 'gliclazide',
    'glimepiride', 'glibenclamide', 'pioglitazone', 'empagliflozin',
    'dapagliflozin', 'amlodipine', 'losartan', 'valsartan', 'telmisartan',
    'irbesartan', 'olmesartan', 'candesartan', 'lisinopril', 'enalapril',
    'captopril', 'atenolol', 'metoprolol', 'bisoprolol', 'carvedilol',
    'propranolol', 'hydrochlorothiazide', 'furosemide', 'spironolactone',
    'atorvastatin', 'rosuvastatin', 'simvastatin', 'pravastatin',
    'fenofibrate', 'aspirin', 'clopidogrel', 'warfarin', 'omeprazole',
    'esomeprazole', 'pantoprazole', 'lansoprazole', 'ranitidine',
    'famotidine', 'amoxicillin', 'clavulanate', 'azithromycin',
    'clarithromycin', 'cefalexin', 'cefuroxime', 'cefixime', 'ciprofloxacin',
    'levofloxacin', 'doxycycline', 'metronidazole', 'cotrimoxazole',
    'cetirizine', 'loratadine', 'levocetirizine', 'montelukast', 'salbutamol',
    'prednisone', 'methylprednisolone', 'dexamethasone', 'levothyroxine',
    'docusate', 'bisacodyl', 'loperamide', 'domperidone', 'metoclopramide',
    'ondansetron', 'gabapentin', 'pregabalin', 'amitriptyline', 'sertraline',
    'escitalopram', 'fluoxetine', 'alprazolam', 'clonazepam', 'diazepam',
  ];
}

class _MedBuilder {
  final String name;
  final String strength;
  final StringBuffer instruction = StringBuffer();
  String? quantity;
  String? refills;
  _MedBuilder(this.name, this.strength);

  ParsedMedication build() {
    final raw = instruction.toString().trim();
    String? qty;
    if (quantity != null) {
      qty = '$quantity in total';
    }
    String? ref;
    if (refills != null) {
      final r = refills!.toLowerCase();
      final none = ['0', 'o', 'none', 'nil', 'φ', 'ø', '⌀'].contains(r);
      ref = none ? 'No refills' : '$refills refill(s) allowed';
    }
    return ParsedMedication(
      name: name,
      strength: strength,
      rawInstruction: raw,
      howToTake: SigTranslator.translate(raw),
      quantity: qty,
      refills: ref,
    );
  }
}

// ---------------------------------------------------------------------------
// Prescription shorthand -> plain English
// ---------------------------------------------------------------------------
class SigTranslator {
  static final _sigToken = RegExp(
      r'\b(po|sl|top|gtt|inh|im|iv|sc|qd|bid|tid|qid|qhs|ghs|hs|qam|qpm|qod|prn|ac|pc|stat|tabs?|caps?|q\d+h)\b',
      caseSensitive: false);

  static bool looksLikeSig(String s) => _sigToken.hasMatch(s);

  static const _units = {
    'tab': 'tablet',
    'tabs': 'tablets',
    'tablet': 'tablet',
    'tablets': 'tablets',
    'cap': 'capsule',
    'caps': 'capsules',
    'capsule': 'capsule',
    'capsules': 'capsules',
    'gtt': 'drop',
    'gtts': 'drops',
    'drop': 'drop',
    'drops': 'drops',
    'puff': 'puff',
    'puffs': 'puffs',
    'tsp': 'teaspoon',
    'tbsp': 'tablespoon',
    'ml': 'ml',
  };

  static String translate(String raw) {
    if (raw.trim().isEmpty) return 'No directions found. Ask your pharmacist.';

    final s = raw.toLowerCase().replaceAll(RegExp(r'[.,;]'), ' ');
    var matched = false;

    // Amount per dose ("1 tab", "i tab" (OCR), "2 caps", "5 ml")
    String? amount;
    final a = RegExp(
            r'\b(\d+(?:/\d+)?|one|two|three|i|l)\s*(tabs?|tablets?|caps?|capsules?|gtts?|drops?|puffs?|ml|tsp|tbsp)\b')
        .firstMatch(s);
    if (a != null) {
      var n = a.group(1)!;
      n = {'i': '1', 'l': '1', 'one': '1', 'two': '2', 'three': '3'}[n] ?? n;
      var unit = _units[a.group(2)!] ?? a.group(2)!;
      if (n != '1' && !unit.endsWith('s') && unit != 'ml') unit += 's';
      amount = '$n $unit';
      matched = true;
    }

    // Route
    var verb = 'Take';
    String? route;
    if (RegExp(r'\bpo\b').hasMatch(s)) {
      route = 'by mouth';
    } else if (RegExp(r'\bsl\b').hasMatch(s)) {
      route = 'under the tongue';
    } else if (RegExp(r'\btop\b').hasMatch(s)) {
      verb = 'Apply';
      route = 'on the skin';
    } else if (RegExp(r'\binh\b').hasMatch(s)) {
      verb = 'Inhale';
    } else if (RegExp(r'\b(im|iv|sc)\b').hasMatch(s)) {
      verb = 'Inject';
      route = 'as directed by your doctor';
    }
    if (route != null) matched = true;

    // Frequency
    String? freq;
    final qh = RegExp(r'\bq\s?(\d{1,2})\s?h(?:rs?)?\b').firstMatch(s);
    if (qh != null) {
      freq = 'every ${qh.group(1)} hours';
    } else if (RegExp(r'\bqid\b').hasMatch(s)) {
      freq = '4 times a day';
    } else if (RegExp(r'\btid\b').hasMatch(s)) {
      freq = '3 times a day';
    } else if (RegExp(r'\bbid\b').hasMatch(s)) {
      freq = '2 times a day';
    } else if (RegExp(r'\b(qd|daily)\b').hasMatch(s)) {
      freq = 'once a day';
    } else if (RegExp(r'\b[qg]hs\b|\bhs\b').hasMatch(s)) {
      freq = 'at bedtime';
    } else if (RegExp(r'\bqam\b').hasMatch(s)) {
      freq = 'every morning';
    } else if (RegExp(r'\bqpm\b').hasMatch(s)) {
      freq = 'every evening';
    } else if (RegExp(r'\bqod\b').hasMatch(s)) {
      freq = 'every other day';
    } else if (RegExp(r'\bstat\b').hasMatch(s)) {
      freq = 'immediately (one time)';
    }
    if (freq != null) matched = true;

    // Meals
    String? meals;
    if (RegExp(r'\bac\b|before meals?').hasMatch(s)) {
      meals = 'before meals';
    } else if (RegExp(r'\bpc\b|after meals?').hasMatch(s)) {
      meals = 'after meals';
    } else if (RegExp(r'with (food|meals?)').hasMatch(s)) {
      meals = 'with food';
    }
    if (meals != null) matched = true;

    // Only when needed
    final prn = RegExp(r'\bprn\b').hasMatch(s);
    if (prn) matched = true;

    // Duration ("x7d", "x 7 days", "for 2 weeks")
    String? duration;
    final d = RegExp(r'(?:\bx|\bfor)\s*(\d+)\s*(d|days?|wks?|weeks?)\b')
        .firstMatch(s);
    if (d != null) {
      final unit = d.group(2)!.startsWith('w') ? 'week' : 'day';
      final n = int.parse(d.group(1)!);
      duration = 'for $n $unit${n == 1 ? '' : 's'}';
      matched = true;
    }

    if (!matched) return raw.trim();

    final parts = <String>[
      verb,
      if (amount != null) amount,
      if (route != null) route,
      if (freq != null) freq,
      if (meals != null) meals,
      if (prn) 'only when needed',
      if (duration != null) duration,
    ];
    return '${parts.join(' ')}.';
  }
}
