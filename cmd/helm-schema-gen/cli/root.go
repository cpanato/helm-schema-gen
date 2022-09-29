package cli

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"sigs.k8s.io/release-utils/version"
)

func NewRootCommand() *cobra.Command {
	rootCmd := &cobra.Command{
		Use:           "schema-gen",
		SilenceUsage:  true,
		SilenceErrors: true,
		Short:         "Helm plugin to generate json schema for values yaml",
		Long: `Helm plugin to generate json schema for values yaml

Examples:
  $ helm schema-gen generate values.yaml    # generate schema json
`,
	}

	rootCmd.AddCommand(NewGenerateCmd())
	rootCmd.AddCommand(version.WithFont("starwars"))

	return rootCmd
}

// Execute executes the root command
func Execute() {
	rootCmd := NewRootCommand()
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
