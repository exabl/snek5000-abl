
# vim: set ft=make
# run
$(OBJDIR)/frame.o             :toolbox/frame.f toolbox/FRAMELP
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/mntrlog_block.o     :toolbox/mntrlog_block.f toolbox/MNTRLOGD
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/mntrlog.o           :toolbox/mntrlog.f toolbox/MNTRLOGD
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/mntrtmr_block.o     :toolbox/mntrtmr_block.f toolbox/MNTRLOGD toolbox/MNTRTMRD
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/mntrtmr.o           :toolbox/mntrtmr.f toolbox/MNTRLOGD toolbox/MNTRTMRD toolbox/FRAMELP
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/rprm_block.o        :toolbox/rprm_block.f toolbox/RPRMD
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/rprm.o              :toolbox/rprm.f toolbox/RPRMD toolbox/FRAMELP
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/io_tools_block.o    :toolbox/io_tools_block.f toolbox/IOTOOLD
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/io_tools.o          :toolbox/io_tools.f toolbox/IOTOOLD
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/chkpoint.o          :toolbox/chkpoint.f toolbox/CHKPOINTD
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/chkpt_mstp.o        :toolbox/chkpt_mstp.f toolbox/CHKPTMSTPD toolbox/CHKPOINTD
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/map2D.o             :toolbox/map2D.f toolbox/MAP2D toolbox/FRAMELP
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/stat.o              :toolbox/stat.f toolbox/STATD toolbox/MAP2D toolbox/FRAMELP sgs/SGS
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/stat_IO.o           :toolbox/stat_IO.f toolbox/STATD toolbox/MAP2D toolbox/FRAMELP
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/math_tools.o        :toolbox/math_tools.f
	$(F77) -c $(FL2) -I./ $< -o $@

# $(OBJDIR)/smagorinsky.o       :sgs/smagorinsky.f sgs/SGS sgs/WMLES
$(OBJDIR)/dynsmag.o           :sgs/dynsmag.f sgs/DYN sgs/SGS sgs/WMLES
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/utils.o             :sgs/utils.f sgs/SGS
	$(F77) -c $(FL2) -I./ $< -o $@

$(OBJDIR)/wmles_init.o        :sgs/wmles_init.f sgs/WMLES sgs/../toolbox/FRAMELP
	$(F77) -c $(FL2) -I./ $< -o $@

