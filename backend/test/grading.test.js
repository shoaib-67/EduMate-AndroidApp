import test from 'node:test';
import assert from 'node:assert/strict';
import { cleanQuestion, gradeExam } from '../exam-grading.js';

test('mixed exams grade typed answers, whitespace, wrong and blank answers', () => {
  const questions = [
    { id: 1, question_type: 'mcq', correct_option: 2 },
    { id: 2, question_type: 'fill_blank', correct_answer: 'New Delhi' },
    { id: 3, question_type: 'fill_blank', correct_answer: 'ঢাকা' },
    { id: 4, question_type: 'mcq', correct_option: 0 },
    { id: 5, question_type: 'fill_blank', correct_answer: 'x' },
  ];
  assert.deepEqual(gradeExam(questions, {1: 2, 2: ' new   DELHI ', 3: 'ভুল', 4: null, 5: '  '}, 2, 0.5), {
    score: 35, earned_marks: 3.5, total_marks: 10,
    correct_answers: 2, incorrect_answers: 1, unanswered: 2, total_questions: 5,
  });
  assert.equal(gradeExam(questions, {4: false}, 1, 0).correct_answers, 0);
});

test('question validation preserves MCQ compatibility and rejects missing keys', () => {
  assert.equal(cleanQuestion({question_text:'Capital?',options:['a','b','c','d'],correct_option:0}).question_type, 'mcq');
  assert.equal(cleanQuestion({question_text:'Capital is ___',question_type:'fill_blank',correct_answer:'ঢাকা'}).correct_answer, 'ঢাকা');
  assert.equal(cleanQuestion({question_text:'Missing',question_type:'fill_blank',correct_answer:'  '}), null);
  assert.equal(cleanQuestion({question_text:'Missing',options:['a','b'],correct_option:0}), null);
  assert.equal(cleanQuestion({question_text:'Unknown',question_type:'essay'}), null);
});
