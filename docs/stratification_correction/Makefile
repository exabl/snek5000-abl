program.out:
	gfortran -O2 -fdefault-real-8 -fdefault-double-8 strat_correct.f solve.f -o program.out

lib:
	python -m numpy.f2py -c strat_correct.f -m strat_correct_f

strat_correct.pyf: strat_correct.f
	python -m numpy.f2py $< -m strat_correct_f -h $@

clean:
	rm -f *.so *.o *.out *.pyf
