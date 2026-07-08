class MedicationLibrary {
  static final Map<String, Map<String, String>> _library = {
    'lisinopril': {
      'drugClass': 'ACE Inhibitor',
      'description': 'Used to treat high blood pressure and heart failure. It helps lower blood pressure, which helps prevent strokes, heart attacks, and kidney problems.',
      'sideEffects': 'Dry cough, Dizziness, Headache, Tiredness, Nausea'
    },
    'metformin': {
      'drugClass': 'Biguanide (Antidiabetic)',
      'description': 'Used with a proper diet and exercise program to control high blood sugar in patients with type 2 diabetes. Controlling high blood sugar helps prevent kidney damage, blindness, nerve problems, loss of limbs, and sexual function issues.',
      'sideEffects': 'Nausea, Vomiting, Stomach upset, Diarrhea, Metallic taste'
    },
    'gabapentin': {
      'drugClass': 'Anticonvulsant / Neuropathic Agent',
      'description': 'Used with other medications to prevent and control seizures. It is also used to relieve neuropathic pain (nerve pain) following shingles (a painful rash due to herpes zoster infection) in adults.',
      'sideEffects': 'Drowsiness, Dizziness, Loss of coordination, Double vision, Tremor'
    },
    'aspirin': {
      'drugClass': 'NSAID (Analgesic)',
      'description': 'Used to reduce fever and relieve mild to moderate pain from conditions such as muscle aches, toothaches, common cold, and headaches. It may also be used to reduce pain and swelling in conditions such as arthritis.',
      'sideEffects': 'Upset stomach, Heartburn, Nausea, Easy bruising'
    },
    'ibuprofen': {
      'drugClass': 'NSAID (Analgesic)',
      'description': 'Used to relieve pain from various conditions such as headache, dental pain, menstrual cramps, muscle aches, or arthritis. It is also used to reduce fever and to relieve minor aches and pain due to the common cold or flu.',
      'sideEffects': 'Stomach upset, Nausea, Vomiting, Headache, Dizziness, Drowsiness'
    },
    'atorvastatin': {
      'drugClass': 'HMG-CoA Reductase Inhibitor (Statin)',
      'description': 'Used along with a proper diet to help lower "bad" cholesterol and fats (such as LDL, triglycerides) and raise "good" cholesterol (HDL) in the blood. Lowering cholesterol helps prevent heart disease and strokes.',
      'sideEffects': 'Muscle pain, Joint pain, Diarrhea, Mild sore throat'
    },
    'amlodipine': {
      'drugClass': 'Calcium Channel Blocker',
      'description': 'Used with or without other medications to treat high blood pressure. Lowering high blood pressure helps prevent strokes, heart attacks, and kidney problems. Amlodipine belongs to a class of drugs known as calcium channel blockers.',
      'sideEffects': 'Swelling of ankles/feet, Dizziness, Flushing, Headache, Fatigue'
    },
    'levothyroxine': {
      'drugClass': 'Thyroid Hormone',
      'description': 'Used to treat an underactive thyroid (hypothyroidism). It replaces or provides more thyroid hormone, which is normally produced by the thyroid gland.',
      'sideEffects': 'Hair loss (temporary), Increased sweating, Nervousness, Tremor'
    },
    'albuterol': {
      'drugClass': 'Beta-2 Agonist (Bronchodilator)',
      'description': 'Used to prevent and treat difficulty breathing, wheezing, shortness of breath, coughing, and chest tightness caused by lung diseases such as asthma and chronic obstructive pulmonary disease (COPD).',
      'sideEffects': 'Nervousness, Shaking (tremor), Headache, Throat irritation, Rapid heart rate'
    },
    'omeprazole': {
      'drugClass': 'Proton Pump Inhibitor (PPI)',
      'description': 'Used to treat certain stomach and esophagus problems (such as acid reflux, ulcers). It works by decreasing the amount of acid your stomach makes. It relieves symptoms such as heartburn, difficulty swallowing, and persistent cough.',
      'sideEffects': 'Headache, Stomach pain, Nausea, Diarrhea, Gas'
    },
  };

  static Map<String, String>? getDetails(String name) {
    return _library[name.trim().toLowerCase()];
  }
}
