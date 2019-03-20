package main

import (
	"github.com/pkg/errors"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"os"
)

func main() {
	if err := RootCmd().Execute(); err != nil {
		os.Exit(1)
	}
}

func RootCmd() *cobra.Command {

	cmd := &cobra.Command{
		Use:   "entitlements",
		Short: "API client for creating entitlements specs",
		Long: `
`,
		SilenceUsage: true,
	}
	cmd.AddCommand(CreateCommand())
	cmd.AddCommand(SetValueCmd())
	cmd.AddCommand(GetShipReleaseCommand())

	return cmd
}

func require(vip *viper.Viper, key string) (string, error) {
	value := vip.GetString(key)
	if value == "" {
		return "", errors.Errorf("missing parameter: %s", key)
	}
	return value, nil
}
