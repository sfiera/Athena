/** @file cmdline.h
 *  @brief The header file for the command line option parser
 *  generated by GNU Gengetopt version 2.22.5
 *  http://www.gnu.org/software/gengetopt.
 *  DO NOT modify this file, since it can be overwritten
 *  @author GNU Gengetopt by Lorenzo Bettini */

#ifndef CMDLINE_H
#define CMDLINE_H

/* If we use autoconf.  */
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <stdio.h> /* for FILE */

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#ifndef ARG_PARSER_PACKAGE
/** @brief the program name (used for printing errors) */
#define ARG_PARSER_PACKAGE "Athena"
#endif

#ifndef ARG_PARSER_PACKAGE_NAME
/** @brief the complete program name (used for help and version) */
#define ARG_PARSER_PACKAGE_NAME "Athena"
#endif

#ifndef ARG_PARSER_VERSION
/** @brief the program version */
#define ARG_PARSER_VERSION "0.1"
#endif

enum enum_type { type__NULL = -1, type_arg_ares = 0, type_arg_xsera, type_arg_antares };

/** @brief Where the command line options are stored */
struct athena_args
{
  const char *help_help; /**< @brief Print help and exit help description.  */
  const char *full_help_help; /**< @brief Print help, including hidden options, and exit help description.  */
  const char *version_help; /**< @brief Print version and exit help description.  */
  char * base_arg;	/**< @brief Use base data..  */
  char * base_orig;	/**< @brief Use base data. original value given at command line.  */
  const char *base_help; /**< @brief Use base data. help description.  */
  const char *download_help; /**< @brief Download data help description.  */
  const char *check_help; /**< @brief Preform consistency check help description.  */
  const char *list_help; /**< @brief List file contents help description.  */
  enum enum_type type_arg;	/**< @brief Filetype to output.  */
  char * type_orig;	/**< @brief Filetype to output original value given at command line.  */
  const char *type_help; /**< @brief Filetype to output help description.  */
  char * out_arg;	/**< @brief Output location.  */
  char * out_orig;	/**< @brief Output location original value given at command line.  */
  const char *out_help; /**< @brief Output location help description.  */
  
  unsigned int help_given ;	/**< @brief Whether help was given.  */
  unsigned int full_help_given ;	/**< @brief Whether full-help was given.  */
  unsigned int version_given ;	/**< @brief Whether version was given.  */
  unsigned int base_given ;	/**< @brief Whether base was given.  */
  unsigned int download_given ;	/**< @brief Whether download was given.  */
  unsigned int check_given ;	/**< @brief Whether check was given.  */
  unsigned int list_given ;	/**< @brief Whether list was given.  */
  unsigned int type_given ;	/**< @brief Whether type was given.  */
  unsigned int out_given ;	/**< @brief Whether out was given.  */

} ;

/** @brief The additional parameters to pass to parser functions */
struct arg_parser_params
{
  int override; /**< @brief whether to override possibly already present options (default 0) */
  int initialize; /**< @brief whether to initialize the option structure athena_args (default 1) */
  int check_required; /**< @brief whether to check that all required options were provided (default 1) */
  int check_ambiguity; /**< @brief whether to check for options already specified in the option structure athena_args (default 0) */
  int print_errors; /**< @brief whether getopt_long should print an error message for a bad option (default 1) */
} ;

/** @brief the purpose string of the program */
extern const char *athena_args_purpose;
/** @brief the usage string of the program */
extern const char *athena_args_usage;
/** @brief all the lines making the help output */
extern const char *athena_args_help[];
/** @brief all the lines making the full help output (including hidden options) */
extern const char *athena_args_full_help[];

/**
 * The command line parser
 * @param argc the number of command line options
 * @param argv the command line options
 * @param args_info the structure where option information will be stored
 * @return 0 if everything went fine, NON 0 if an error took place
 */
int arg_parser (int argc, char **argv,
  struct athena_args *args_info);

/**
 * The command line parser (version with additional parameters - deprecated)
 * @param argc the number of command line options
 * @param argv the command line options
 * @param args_info the structure where option information will be stored
 * @param override whether to override possibly already present options
 * @param initialize whether to initialize the option structure my_args_info
 * @param check_required whether to check that all required options were provided
 * @return 0 if everything went fine, NON 0 if an error took place
 * @deprecated use arg_parser_ext() instead
 */
int arg_parser2 (int argc, char **argv,
  struct athena_args *args_info,
  int override, int initialize, int check_required);

/**
 * The command line parser (version with additional parameters)
 * @param argc the number of command line options
 * @param argv the command line options
 * @param args_info the structure where option information will be stored
 * @param params additional parameters for the parser
 * @return 0 if everything went fine, NON 0 if an error took place
 */
int arg_parser_ext (int argc, char **argv,
  struct athena_args *args_info,
  struct arg_parser_params *params);

/**
 * Save the contents of the option struct into an already open FILE stream.
 * @param outfile the stream where to dump options
 * @param args_info the option struct to dump
 * @return 0 if everything went fine, NON 0 if an error took place
 */
int arg_parser_dump(FILE *outfile,
  struct athena_args *args_info);

/**
 * Save the contents of the option struct into a (text) file.
 * This file can be read by the config file parser (if generated by gengetopt)
 * @param filename the file where to save
 * @param args_info the option struct to save
 * @return 0 if everything went fine, NON 0 if an error took place
 */
int arg_parser_file_save(const char *filename,
  struct athena_args *args_info);

/**
 * Print the help
 */
void arg_parser_print_help(void);
/**
 * Print the full help (including hidden options)
 */
void arg_parser_print_full_help(void);
/**
 * Print the version
 */
void arg_parser_print_version(void);

/**
 * Initializes all the fields a arg_parser_params structure 
 * to their default values
 * @param params the structure to initialize
 */
void arg_parser_params_init(struct arg_parser_params *params);

/**
 * Allocates dynamically a arg_parser_params structure and initializes
 * all its fields to their default values
 * @return the created and initialized arg_parser_params structure
 */
struct arg_parser_params *arg_parser_params_create(void);

/**
 * Initializes the passed athena_args structure's fields
 * (also set default values for options that have a default)
 * @param args_info the structure to initialize
 */
void arg_parser_init (struct athena_args *args_info);
/**
 * Deallocates the string fields of the athena_args structure
 * (but does not deallocate the structure itself)
 * @param args_info the structure to deallocate
 */
void arg_parser_free (struct athena_args *args_info);

/**
 * Checks that all the required options were specified
 * @param args_info the structure to check
 * @param prog_name the name of the program that will be used to print
 *   possible errors
 * @return
 */
int arg_parser_required (struct athena_args *args_info,
  const char *prog_name);

extern const char *arg_parser_type_values[];  /**< @brief Possible values for type. */


#ifdef __cplusplus
}
#endif /* __cplusplus */
#endif /* CMDLINE_H */
