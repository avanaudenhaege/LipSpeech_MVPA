
clean:
	rm -rf stimuli

stimuli:
	wget https://osf.io/download/v4ne3/?view_only=e21d5b119a344453bd18748c0145cf26 -O tmp.zip
	unzip -q tmp.zip
	rm -rf __MACOSX tmp.zip
	mv stim stimuli
