package cmd

import (
	"fmt"
	"io/ioutil"
	"os"

	"github.com/karuppiah7890/go-jsonschema-generator"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v2"
	"sigs.k8s.io/release-utils/version"
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:           "schema-gen <values-yaml-file>",
	SilenceUsage:  true,
	SilenceErrors: true,
	Short:         "Helm plugin to generate json schema for values yaml",
	Long: `Helm plugin to generate json schema for values yaml

Examples:
  $ helm schema-gen values.yaml    # generate schema json
`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if len(args) == 0 {
			return fmt.Errorf("pass one values yaml file")
		}
		if len(args) != 1 {
			return fmt.Errorf("schema can be generated only for one values yaml at once")
		}

		valuesFilePath := args[0]
		values := make(map[string]interface{})
		valuesFileData, err := ioutil.ReadFile(valuesFilePath)
		if err != nil {
			return fmt.Errorf("failed to read file %q: %v", valuesFilePath, err)
		}

		err = yaml.Unmarshal(valuesFileData, &values)
		if err != nil {
			return fmt.Errorf("failed to unmarshall values: %v", err)
		}

		s := &jsonschema.Document{}
		s.ReadDeep(&values)
		fmt.Println(s)

		return nil
	},
}

// Execute executes the root command
func Execute() {
	rootCmd.AddCommand(version.WithFont("starwars"))

	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
