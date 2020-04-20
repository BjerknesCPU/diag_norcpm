default:
	@sh cp_A150yr_to_B400yr.sh
updateall:
	rm -f orig/*
	rm -f *.yml
	cp ../../A*.yml orig/
	rm orig/A6*.yml orig/A0*.yml
	# f09 sample not done yet
	sed -i -e's/f09_5AGCMs_NASPG_sample/f09_5AGCMs_NASPG_sample_notdone/' orig/*.yml
clean:
	rm -f orig/*.yml
