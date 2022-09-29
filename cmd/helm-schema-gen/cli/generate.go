package cli

import (
	"fmt"
	"os"

	"github.com/karuppiah7890/go-jsonschema-generator"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v2"
)

func NewGenerateCmd() *cobra.Command {
	generateCmd := &cobra.Command{
		Use:   "generate <values-yaml-file>",
		Short: "generate json schema for values yaml",
		RunE: func(cmd *cobra.Command, args []string) error {
			if len(args) == 0 {
				return fmt.Errorf("pass one values yaml file")
			}
			if len(args) != 1 {
				return fmt.Errorf("schema can be generated only for one values yaml at once")
			}

			valuesFilePath := args[0]
			values := make(map[string]interface{})
			valuesFileData, err := os.ReadFile(valuesFilePath)
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

	return generateCmd
}
