// Copyright © 2017 Jade Iqbal <jadeiqbal@fastmail.com>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package cmd

import (
	"fmt"

	"os"

	"encoding/json"
	"io/ioutil"

	"github.com/spf13/cobra"
)

// stopCmd represents the stop command
var stopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop a running EC2 instance",
	Long: `
Stops a Parsec EC2 instance created using the start command. Under the
hood this command runs 'terraform destroy', with removes all AWS resources
that are identified for creation in the terraform template.

This command depends on session information that is created by the start
command and stored in $HOME/.parsec-ec2/currentSession.json, so if this
has been manually modified or removed after running the start command,
the stop command will not execute. In this situation it is still possible
to manually run 'terraform destroy'.

Example:

parsec-ec2 stop
`,
	Run: func(cmd *cobra.Command, args []string) {
		currentSessionFile := fmt.Sprintf("%s/currentSession.json", appFolder)

		bytes, err := ioutil.ReadFile(currentSessionFile)
		if err != nil {
			fmt.Println(`
No session information found.

If you think there may still be a running instance, you can try
'cd $HOME/.parsec-ec2 && terraform destroy', or alternatively
refer to the EC2 dashboard on the AWS website.`)
			os.Exit(1)
		}

		var currentSessionVars TfVars

		err = json.Unmarshal(bytes, &currentSessionVars)
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		err = os.Remove(currentSessionFile)
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		destroy := constructTerraformCommand(currentSessionVars, []string{"destroy", "-force"})

		err = executeTerraformCommandAndPrintOutput(destroy)
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		fmt.Println(`
All AWS resources have been successfully terminated.`)
	},
}

func init() {
	RootCmd.AddCommand(stopCmd)
}
