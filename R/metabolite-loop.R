
# Ambiguous metabolites loop#

amb.met.loop <- function(exp_dat, graph_skel, dat, dat_compl, DE, glmulti_method, exposure, met_map, adjust_method, round_number, adjM_norename, met_group, CC_ind) {

  # exp_dat: exposure/phenotype data
  # graph_skel: estimated DAG skeleton of samples x metabolites data matrix
  # dat: renamed samples x metabolites data matrix
  # dat_compl: renamed samples x metabolites data matrix (typically same as dat)
  # DE: indicator if direct effects were already identified, here set to NA
  # glmulti_method: choose method for glmulti-function
  # exposure: name of considered exposure variable
  # met_map: mapping information between old and new metabolite names
  # adjust_method: select adjustment method(s), e.g. "fdr" or c("fdr","bonferroni"), see p.adjust.methods for available options
  # round_number: actual round number in ambiguous metabolites loop, initiate with round_number=1
  # adjM_norename: not renamed adjacency matrix of metabolite DAG
  # met_group: name of investigated metabolite group

  netin_amb <- list()
  netin_direct <- list()
  netin_sum <- list()
  con_comp <- list()
  MinMod_list <- list()

  MinMod_exp <- c(paste(colnames(exp_dat), collapse = ", ")) # record covariates for minimal model (without any adjacency set)

  repeat{
    print(paste(round_number, ". iteration", sep = ""))
    if (round_number > 1) print(paste0("Connected component ", CC_ind, sep = ""))

    # estimate direct effects of predefined exposure on each network-variable, causal models that agree with the input-network: models are adjusted for all possible combinations of direct neighbors (==variables in adjacency set) -> Output is multiset of possible effects:
    net_coupler_in_AC <- net.coupler.in(graph_skel = graph_skel, dat = dat, dat_compl = dat_compl, exp_dat = exp_dat, DE = DE, glmulti_method = glmulti_method)

    # return results (e.g. p-values, etc.) for specific exposure:
    sum_netin <- getExp.coef(object = net_coupler_in_AC, outcome = colnames(dat), exposure = exposure)

    # get original metabolite names back:
    sum_netin <- merge(sum_netin, as.data.frame(met_map), by = "Outcome")

    # save current minimal model:
    MinMod_list[[length(MinMod_list) + 1]] <- MinMod_exp
    names(MinMod_list)[length(MinMod_list)] <- paste0(round_number, ". iteration")

    sum_stat_netin <- mult.stat(sum_netin = sum_netin, MinMod = MinMod_exp, adjust_method = adjust_method, round_number = round_number) # calculate summary statistics and determine direct and ambiguous effects

    netin_amb[[length(netin_amb) + 1]] <- sum_stat_netin$amb # summary statistics for metabolites on which predefined exposure has ambiguous effect
    netin_direct[[length(netin_direct) + 1]] <- sum_stat_netin$direct # summary statistics for metabolites on which predefined exposure has direct effect
    netin_sum[[length(netin_sum) + 1]] <- sum_stat_netin$sum_netin_sum_adj_FV # summary statistics for meatbolites including round-number information
    names(netin_amb)[length(netin_amb)] <- paste0(round_number, ". iteration")
    names(netin_direct)[length(netin_direct)] <- paste0(round_number, ". iteration")
    names(netin_sum)[length(netin_sum)] <- paste0(round_number, ". iteration")

    numb_DE <- dim(netin_direct[[length(netin_direct)]])[1]
    numb_AMB <- dim(netin_amb[[length(netin_amb)]])[1]

    # check if direct effects!=0 and/or ambiguous effects!=0, otherwise quit:
    if (numb_DE == 0 | numb_AMB == 0) {
      cat(paste("\n ***no direct and/or ambiguous effects identified -> stop algorithm after ", round_number, ". iteration*** \n", sep = ""))
      break
    }

    # if there are direct and ambiguous effects of predefined exposure on metabolites -> extract connected components:
    exposure_list <- list(netin_sum[[length(netin_sum)]])
    names(exposure_list) <- exposure

    # extract connected components for direct and ambiguous effects for predefined exposure:
    con_comp[[length(con_comp) + 1]] <- get.con.comp(exposure_names = c(exposure), exposure_list = exposure_list, adjM_norename = adjM_norename, met_group = met_group)
    names(con_comp)[length(con_comp)] <- paste0(round_number, ". iteration")

    CC_NC_res <- con_comp[[length(con_comp)]]$NC_res[[1]] # original summary statistics for all metabolites including membership in specific connected components for redmeat

    EXPOSURECC <- CC_NC_res %>% dplyr::select(Metabolite, contains("CC")) # Metabolites and membership in specific connected component for redmeat

    # check if current connected component index number CC_ind>dim(EXPOSURECC)[2]-1, if TRUE quit:
    if (CC_ind > dim(EXPOSURECC)[2] - 1) {
      cat(paste("\n ***maximum number of connected components reached -> stop algorithm after evaluating ", CC_ind - 1, ". connected component*** \n", sep = ""))
      break
    }

    names_EXPOSURECC <- EXPOSURECC[which(EXPOSURECC[, CC_ind + 1] == TRUE), 1] # Metabolites which are in specific connected component for redmeat !!!attention, only for one connected component!!!!, loop if more than one?

    # intersection of metabolites with direct effect from predefined exposure and connected components: are there direct effect metabolites which are also in specific connected components, i.e. are connected to at least one other metabolite?
    DE_norename <- intersect(as.character(unlist(names_EXPOSURECC)), as.character(netin_direct[[length(netin_direct)]]$Metabolite))

    DE <- c(DE, met_map[which(met_map[, 1] %in% DE_norename), 2]) # get back short metabolite names

    # intersection of metabolites with ambiguous effect from predefined exposure and connected components: are there ambiguous effect metabolites which are also in specific connected components, i.e. are connected to at least one other metabolite?
    AMB_norename <- intersect(as.character(unlist(names_EXPOSURECC)), as.character(netin_amb[[length(netin_amb)]]$Metabolite))

    AMB <- met_map[which(met_map[, 1] %in% AMB_norename), 2] # get back short metabolite names

    numb_DE_intersect <- length(DE)
    numb_AMB_intersect <- length(AMB)

    # check if intersect(direct effects,connected components)!=0 and/or intersect(ambiguous effects,connected components)!=0, otherwise quit:
    if (numb_DE_intersect == 0 | numb_AMB_intersect == 0) {
      cat(paste("\n ***no direct and/or ambiguous effects in specific connected component -> stop algorithm after ", round_number, ". iteration*** \n", sep = ""))
      break
    }

    # define new minimal model, now including connected component direct effect metabolite as fixed variable:
    MinMod_exp <- paste0(paste0(DE, collapse = ", "), ", ", MinMod_exp)

    # define new metabolite data matrix only including ambiguous effect metabolites from predefined exposure which are also in specific connected component:
    dat <- as.matrix(dat[, c(which(colnames(dat) %in% AMB)), drop = FALSE])

    # add connected component direct effect metabolite data to exp_dat:
    exp_dat <- cbind(dat_compl[, c(which(colnames(dat_compl) %in% DE))], exp_dat)
    colnames(exp_dat)[1:length(DE)] <- DE

    round_number <- round_number + 1
  }

  return(list(netin_direct = netin_direct, netin_amb = netin_amb, netin_sum = netin_sum, con_comp = con_comp, MinMod_list = MinMod_list))
}

# Ambiguous metabolites loop for several connected components#

amb.met.loop.CC <- function(exp_dat, graph_skel, dat, dat_compl, DE, glmulti_method, exposure, met_map, adjust_method, round_number, adjM_norename, met_group) {

  # exp_dat: exposure/phenotype data
  # graph_skel: estimated DAG skeleton of samples x metabolites data matrix
  # dat: renamed samples x metabolites data matrix
  # dat_compl: renamed samples x metabolites data matrix (typically same as dat)
  # DE: indicator if direct effects were already identified, here set to NA
  # glmulti_method: choose method for glmulti-function
  # exposure: name of considered exposure variable
  # met_map: mapping information between old and new metabolite names
  # adjust_method: select adjustment method(s), e.g. "fdr" or c("fdr","bonferroni"), see p.adjust.methods for available options
  # round_number: actual round number in ambiguous metabolites loop, initiate with round_number=1
  # adjM_norename: not renamed adjacency matrix of metabolite DAG
  # met_group: name of investigated metabolite group

  amb_met_loop <- list()

  CC_numb_max <- dim(dat)[2]

  for (i in 1:CC_numb_max) {
    amb_met_loop[[i]] <- amb.met.loop(exp_dat = exp_dat, graph_skel = graph_skel, dat = dat, dat_compl = dat_compl, DE = DE, glmulti_method = glmulti_method, exposure = exposure, met_map = met_map, adjust_method = adjust_method, round_number = round_number, adjM_norename = adjM_norename, met_group = met_group, CC_ind = i)
    names(amb_met_loop)[i] <- paste0("conn_comp_", i)

    if (length(amb_met_loop[[i]]$con_comp) == 0) {
      break
    }
    if (length(amb_met_loop[[i]]$con_comp[[1]]$all_CC) < i) {
      break
    }
  }

  return(amb_met_loop)
}

# ambiguous metabolites loop for net.coupler.out. survival analysis#

amb.met.loop.out.surv <- function(exp_dat, graph_skel, dat, dat_compl, DE, survival_obj, always_set, met_map, adjust_method, round_number) {

  # exp_dat: exposure/phenotype data
  # graph_skel: estimated DAG skeleton of samples x metabolites data matrix
  # dat: renamed samples x metabolites data matrix
  # dat_compl: renamed samples x metabolites data matrix (typically same as dat)
  # DE: indicator if direct effects were already identified, here set to NA
  # survival_obj: "survival" object
  # always_set: fixed set of covariates always included in model
  # met_map: mapping information between old and new metabolite names
  # adjust_method: select adjustment method(s), e.g. "fdr" or c("fdr","bonferroni"), see p.adjust.methods for available options
  # round_number: actual round number in ambiguous metabolites loop, initiate with round_number=1

  netout_amb <- list()
  netout_direct <- list()
  netout_sum <- list()

  repeat{
    print(paste(round_number, ". iteration", sep = ""))

    # estimate direct effects of metabolites on time-to-diabetes-incident: models are adjusted for all possible combinations of direct neighbors (==variables in adjacency set) -> Output is multiset of possible effects:
    net_coupler_out <- net.coupler.out(graph_skel = graph_skel, dat = dat, dat_compl = dat_compl, exp_dat = exp_dat, DE = DE, survival_obj = survival_obj, always_set = always_set, name_surv_obj = deparse(substitute(survival_obj)))

    # return results:
    sum_netout <- getExp.coef.out(object = net_coupler_out, metabolite = colnames(dat))

    # get original metabolite names back:
    sum_netout <- merge(sum_netout, as.data.frame(met_map), by = "Outcome")

    sum_stat_netout <- mult.stat.surv(sum_netout = sum_netout, adjust_method = adjust_method, round_number = round_number) # calculate summary statistics and determine direct and ambiguous effects

    netout_amb[[length(netout_amb) + 1]] <- sum_stat_netout$amb # summary statistics for metabolites which have ambiguous effect on time-to-diabetes-incident
    netout_direct[[length(netout_direct) + 1]] <- sum_stat_netout$direct # summary statistics for metabolites which have direct effect on time-to-diabetes-incident
    netout_sum[[length(netout_sum) + 1]] <- sum_stat_netout$sum_netout_sum_adj_FV # summary statistics for meatbolites including round-number information
    names(netout_amb)[length(netout_amb)] <- paste0(round_number, ". iteration")
    names(netout_direct)[length(netout_direct)] <- paste0(round_number, ". iteration")
    names(netout_sum)[length(netout_sum)] <- paste0(round_number, ". iteration")

    numb_DE <- dim(netout_direct[[length(netout_direct)]])[1]
    numb_AMB <- dim(netout_amb[[length(netout_amb)]])[1]

    # check if direct effects!=0 and/or ambiguous effects!=0, otherwise quit:
    if (numb_DE == 0 | numb_AMB == 0) {
      cat(paste("\n ***no direct and/or ambiguous effects identified -> stop algorithm after ", round_number, ". iteration*** \n", sep = ""))
      break
    }

    # if there are direct and ambiguous effects of metabolites on time-to-diabetes-incident -> continue:

    # names of direct effect metabolites:
    DE <- c(DE, netout_direct[[length(netout_direct)]]$Outcome)
    DE_1 <- netout_direct[[length(netout_direct)]]$Outcome

    print("here1")

    # define new metabolite data matrix only including ambiguous effect metabolites:
    dat <- as.matrix(dat[, c(which(colnames(dat) %in% netout_amb[[length(netout_amb)]]$Outcome)), drop = FALSE])

    print("here2")
    print(colnames(exp_dat))

    # add direct effect metabolite data to exp_dat:
    exp_dat <- cbind(dat_compl[, c(which(colnames(dat_compl) %in% DE_1))], exp_dat)
    colnames(exp_dat)[1:length(DE_1)] <- DE_1

    print(colnames(exp_dat))

    # add direct effect metabolites to always set:
    always_set <- paste0(paste0(DE_1, collapse = " + "), sep = " + ", always_set)

    print(always_set)

    round_number <- round_number + 1
  }

  return(list(netout_direct = netout_direct, netout_amb = netout_amb, netout_sum = netout_sum))
}
