; RUN: opt < %s -analyze -delinearize | FileCheck %s

; Derived from the following code:
;
; void foo(long n, long m, double A[n][m]) {
;   for (long i = 0; i < n; i++)
;     for (long j = 0; j < m; j++)
;       A[i][j] = 1.0;
; }

; AddRec: {{%A,+,(8 * %m)}<%for.i>,+,8}<%for.j>
; CHECK: Base offset: %A
; CHECK: ArrayDecl[UnknownSize][%m] with elements of sizeof(double) bytes.
; CHECK: ArrayRef[{0,+,1}<nuw><nsw><%for.i>][{0,+,1}<nuw><nsw><%for.j>]

; AddRec: {(-8 + (8 * %m) + %A),+,(8 * %m)}<%for.i>
; CHECK: Base offset: %A
; CHECK: ArrayDecl[UnknownSize] with elements of sizeof(double) bytes.
; CHECK: ArrayRef[{(-1 + %m),+,%m}<%for.i>]

define void @foo(i64 %n, i64 %m, double* %A) {
entry:
  br label %for.i

for.i:
  %i = phi i64 [ 0, %entry ], [ %i.inc, %for.i.inc ]
  %tmp = mul nsw i64 %i, %m
  br label %for.j

for.j:
  %j = phi i64 [ 0, %for.i ], [ %j.inc, %for.j ]
  %vlaarrayidx.sum = add i64 %j, %tmp
  %arrayidx = getelementptr inbounds double* %A, i64 %vlaarrayidx.sum
  store double 1.0, double* %arrayidx
  %j.inc = add nsw i64 %j, 1
  %j.exitcond = icmp eq i64 %j.inc, %m
  br i1 %j.exitcond, label %for.i.inc, label %for.j

for.i.inc:
  %i.inc = add nsw i64 %i, 1
  %i.exitcond = icmp eq i64 %i.inc, %n
  br i1 %i.exitcond, label %end, label %for.i

end:
  ret void
}
