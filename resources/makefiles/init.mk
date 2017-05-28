show:
	@echo "show_<resource>"

show_state: init
	cat $(BUILD)/terraform.tfstate

refresh: init
	cd $(BUILD); $(TF_REFRESH)

init: | $(TF_PROVIDER) $(AMI_VAR)

get_vpc_id:
	$(SCRIPTS)/get-vpc-id.sh

$(BUILD): init_build_dir

$(TF_PROVIDER): update_provider

$(AMI_VAR): update_ami

$(SITE_CERT): gen_certs

init_build_dir:
	@mkdir -p $(BUILD)
	@cp -rf $(RESOURCES)/cloud-config $(BUILD)
	@cp -rf $(RESOURCES)/policies $(BUILD)
	@$(SCRIPTS)/substitute-CLUSTER-NAME.sh $(BUILD)/cloud-config/s3-cloudconfig-bootstrap.sh

update_ami:	| $(BUILD)
	# Generate default AMI ids
	$(SCRIPTS)/get-ami.sh > $(BUILD)/$(AMI_VAR)

update_provider: | $(BUILD)
	# Generate tf provider
	$(SCRIPTS)/gen-provider.sh > /dev/null 2>&1 &&  $(SCRIPTS)/gen-provider.sh > $(BUILD)/$(TF_PROVIDER)

gen_certs: $(BUILD)
	@cp -rf $(RESOURCES)/certs $(BUILD); sed -i '' "s/DOMAIN/$(APP_DOMAIN)/g" $(BUILD)/certs/*
	@if [ ! -f "$(SITE_CERT)" ] ; \
	then \
		$(MAKE) -C $(CERTS) ; \
	fi

clean_certs:
	rm -f $(CERTS)/*.pem

.PHONY: init show show_state refresh update_ami update_provider init_build_dir
.PHONY: gen_certs clean_certs