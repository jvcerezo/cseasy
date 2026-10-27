const _topicLabels = {
  'number_series': 'Number Series',
  'percentage': 'Percentage',
  'ratio_proportion': 'Ratio & Proportion',
  'work': 'Work Problems',
  'distance_rate_time': 'Distance, Rate & Time',
  'age': 'Age Problems',
  'interest': 'Simple & Compound Interest',
  'averages': 'Averages',
  'fractions_operations': 'Fractions & Operations',
  'consecutive_integers': 'Consecutive Integers',
  'syllogisms': 'Syllogisms',
  'ordering': 'Ordering & Arrangement',
  'data_interpretation': 'Data Interpretation',
  'coding_decoding': 'Coding & Decoding',
  'letter_series': 'Letter Series',
  'symbolic_logic': 'Symbolic Logic',
  'assumptions_conclusions': 'Assumptions & Conclusions',
  'spelling': 'Spelling',
  'filing_order': 'Alphabetical Filing',
  'constitution': '1987 Constitution',
  'code_of_conduct': 'Code of Conduct (RA 6713)',
  'human_rights': 'Peace & Human Rights',
  'environment': 'Environment Laws',
  'vocabulary': 'Vocabulary',
  'antonyms': 'Antonyms',
  'analogy': 'Word Analogy',
  'grammar': 'Grammar & Usage',
  'reading_comprehension': 'Reading Comprehension',
  'paragraph_organization': 'Paragraph Organization',
  'sentence_completion': 'Sentence Completion',
  'error_recognition': 'Error Recognition',
  'filipino_vocabulary': 'Talasalitaan (Filipino)',
  'filipino_grammar': 'Wastong Gamit (Filipino)',
  'sawikain': 'Sawikain (Filipino)',
  'filipino_reading': 'Pag-unawa sa Binasa (Filipino)',
};

/// Display name for a content topic key; falls back to title-casing the key.
String topicLabel(String topic) =>
    _topicLabels[topic] ??
    topic
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
