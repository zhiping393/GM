#!/usr/bin/env Rscript

# working path
setwd("community_assembly/working_folder/")

# Loading necessary packages and data
library(tidyverse)
packageVersion("tidyverse") # for dataframe processing

## [1] '2.0.0'
library(vegan)
packageVersion("vegan") # for ecological applications

## [1] '2.6.10'
library(viridis)
library(cowplot) # Pretty plotting
library(here)

# Load required data
source(here("setup.R"))

## Set up input and output directories
outputs.fp <- here("outputs")
figures.fp <- here("figures")

if (!dir.exists(outputs.fp)) {dir.create(outputs.fp)}
if (!dir.exists(figures.fp)) {dir.create(figures.fp)}


# Read in assembly analysis results
betanull.lf <- read_csv(file = paste0(outputs.fp, "/betanull.lf.csv"))
betanull_consecutive.lf <- read_csv(file = paste0(outputs.fp, "/betanull.consecutive.lf.csv"))


# Change variables into a factors
betanull.lf <- betanull.lf %>%
  mutate(across(starts_with("TempCondition"), ~ factor(.x, 
                                               levels = c("Cold-Cold", 
                                                          "Warm-Warm", 
                                                          "Warm-Cold")))) %>%
  mutate(EpochType = factor(EpochType, 
                            levels = c("Holocene", 
                                       "LGS:Holocene", 
                                       "LGS", 
                                       "Pre-LGS:LGS", 
                                       "Pre-LGS"))) %>%
  mutate(Assembly_Process = factor(Assembly_Process, 
                                   levels = c("Homogenous selection",
                                              "Heterogenous selection",
                                              "Homogenizing dispersal",
                                              "Dispersal limitation and drift",
                                              "Drift")))

# Change variables into a factors
betanull_consecutive.lf <- betanull_consecutive.lf %>%
  mutate(across(starts_with("TempCondition"), ~ factor(.x, 
                                                       levels = c("Cold-Cold", 
                                                                  "Warm-Warm", 
                                                                  "Warm-Cold")))) %>%
  mutate(EpochType = factor(EpochType, 
                            levels = c("Holocene", 
                                       "LGS:Holocene", 
                                       "LGS", 
                                       "Pre-LGS:LGS", 
                                       "Pre-LGS"))) %>%
  mutate(Assembly_Process = factor(Assembly_Process, 
                                   levels = c("Homogenous selection",
                                              "Heterogenous selection",
                                              "Homogenizing dispersal",
                                              "Dispersal limitation and drift",
                                              "Drift")))



# Calculate proportions of pairwise comparisons overall
#### ====================================================================== ####
# Proportions across all samples
betanull.lf %>%
  select(Site1, Site2, BetaNTI, RCBC, Assembly_Process) %>%
  group_by(Assembly_Process) %>%
  tally() %>%
  mutate(Total = sum(n),
         Percent = round(100*n/Total, digits = 2)) %>%
  arrange(desc(Percent)) %>% knitr::kable()



# Temperature type
temptype.plot.prop.df <- betanull.lf %>%
  select(Site1, Site2, Assembly_Process, TempConditionType) %>%
  group_by(TempConditionType, Assembly_Process) %>%
  tally() %>% 
  ungroup() %>% group_by(TempConditionType) %>%
  mutate(Total = sum(n),
         Percent = 100*n/Total)

temptype.plot.prop <- temptype.plot.prop.df %>%
  ggplot(aes(x= TempConditionType, y = Percent, 
             fill = Assembly_Process)) +
  facet_wrap(~TempConditionType, shrink = TRUE, drop = TRUE, scales = "free_x") +
  geom_bar(stat = "identity") +
  scale_fill_manual(name = "Assembly Process", values = fill_assembly, 
                    breaks = assembly_levels, 
                    labels = assembly_labels) +
  xlab("") +
  scale_y_continuous(expand = c(0,0)) +
  scale_x_discrete(expand = c(0,0)) +
  #coord_cartesian(expand = c(0,0)) +
  theme_bw() + 
  theme(axis.text.x = element_blank(),
        axis.title.y = element_text(size = rel(2)),
        axis.text.y = element_text(size = rel(1.5)),
        axis.ticks.x = element_blank(),
        strip.text = element_text(size = rel(1)),
        strip.placement = "outside",
        legend.position = "bottom")

temptype.plot.prop.legend <- get_legend(temptype.plot.prop)
#type.plot.prop <- type.plot.prop + theme(legend.position = "none")

ggsave(temptype.plot.prop, 
       filename = paste0(figures.fp, "/tempType_prop.png"),
       width = 10, height = 10, dpi = 400)
temptype.plot.prop
