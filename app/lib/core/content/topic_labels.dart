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
  'calendar': 'Calendar Problems',
  'exact_match': 'Checking & Comparing',
  'filing_order': 'Alphabetical Filing',
};

/// Display name for a content topic key; falls back to title-casing the key.
String topicLabel(String topic) =>
    _topicLabels[topic] ??
    topic
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
