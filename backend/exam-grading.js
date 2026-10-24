export function normalizeAnswer(value) {
  return String(value ?? '').normalize('NFKC').trim().replace(/\s+/gu, ' ').toLocaleLowerCase('en');
}

export function cleanQuestion(q) {
  const type = q?.question_type ?? 'mcq';
  const text = typeof q?.question_text === 'string' ? q.question_text.trim() : '';
  if (!text || text.length > 5000 || !['mcq', 'fill_blank'].includes(type)) return null;
  if (type === 'fill_blank') {
    const answer = typeof q.correct_answer === 'string' ? q.correct_answer.trim() : '';
    if (!answer || answer.length > 500) return null;
    return { question_type: type, question_text: text, options: [], correct_option: 0, correct_answer: answer };
  }
  const options = Array.isArray(q.options) ? q.options.map((v) => typeof v === 'string' ? v.trim() : '') : [];
  if (options.length !== 4 || options.some((v) => !v || v.length > 1000) ||
      !Number.isInteger(q.correct_option) || q.correct_option < 0 || q.correct_option > 3) return null;
  return { question_type: type, question_text: text, options, correct_option: q.correct_option, correct_answer: null };
}

export function gradeExam(questions, answers, perMark, negativeMark) {
  let correct = 0;
  let incorrect = 0;
  for (const q of questions) {
    if (!Object.hasOwn(answers, String(q.id))) continue;
    const answer = answers[String(q.id)];
    if (q.question_type === 'fill_blank') {
      if (typeof answer !== 'string' || !normalizeAnswer(answer)) continue;
      if (normalizeAnswer(answer) === normalizeAnswer(q.correct_answer)) correct++;
      else incorrect++;
    } else {
      if (!Number.isInteger(answer) || answer < 0 || answer > 3) continue;
      if (answer === q.correct_option) correct++;
      else incorrect++;
    }
  }
  const total = questions.length * Number(perMark);
  const earned = Math.round(Math.max(0, correct * Number(perMark) - incorrect * Number(negativeMark)) * 100) / 100;
  return {
    score: total ? Math.round(earned / total * 10000) / 100 : 0,
    earned_marks: earned, total_marks: total, correct_answers: correct,
    incorrect_answers: incorrect, unanswered: questions.length - correct - incorrect,
    total_questions: questions.length,
  };
}
