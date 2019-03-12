package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/url"
	"os"
	"strings"

	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/log/level"
	"github.com/pkg/errors"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func CreateCommand() *cobra.Command {
	vip := viper.New()

	cmd := &cobra.Command{
		Use:   "create-spec",
		Short: "API client for creating entitlements specs",
		Long: `
`,
		RunE: func(cmd *cobra.Command, args []string) error {
			stdoutLogger := log.NewLogfmtLogger(os.Stdout)
			stdoutLogger = log.With(stdoutLogger, "ts", log.DefaultTimestampUTC)
			if vip.GetBool("verbose") {
				stdoutLogger = level.NewFilter(stdoutLogger, level.AllowDebug())
			} else {
				stdoutLogger = level.NewFilter(stdoutLogger, level.AllowWarn())
			}

			upstreamURL := vip.GetString("replicated-api-server")
			upstream, err := url.Parse(upstreamURL)

			if err != nil {
				return errors.Wrapf(err, "parse replicated-api-server URL %s", upstreamURL)
			}

			token, err := require(vip, "replicated-api-token")
			if err != nil {
				return errors.Wrapf(err, "missing replicated-api-token or REPLICATED_API_TOKEN")
			}

			targetFile := vip.GetString("spec-file")
			spec, err := ioutil.ReadFile(targetFile)
			if err != nil {
				return errors.Wrapf(err, "read spec file %s", targetFile)
			}

			specName, err := require(vip, "spec-name")
			if err != nil {
				return errors.Wrapf(err, "missing spec-name")
			}

			client := &GraphQLClient{
				GQLServer: upstream,
				Token:     token,
				Logger:    stdoutLogger,
			}

			espec, err := client.CreateEntitlementSpec(specName, string(spec))

			if err != nil {
				return errors.Wrap(err, "create spec")
			}

			bytes, _ := json.MarshalIndent(espec, "", "  ")
			fmt.Printf("%s\n", bytes)

			return nil
		},
	}

	cmd.Flags().String("replicated-api-token", "", "Token to use to communicate with https://g.replicated.com")
	cmd.Flags().String("replicated-app", "", "upstream g. address")
	cmd.Flags().String("spec-file", "entitlements.yaml", "spec file to promote")
	cmd.Flags().String("spec-name", "", "spec file to promote")

	cmd.Flags().String("replicated-api-server", "https://g.replicated.com/graphql", "upstream g. address")
	cmd.Flags().BoolP("verbose", "p", false, "verbose logging")

	vip.BindPFlags(cmd.Flags())
	vip.BindPFlags(cmd.PersistentFlags())
	vip.AutomaticEnv()
	vip.SetEnvKeyReplacer(strings.NewReplacer("-", "_"))
	return cmd
}
