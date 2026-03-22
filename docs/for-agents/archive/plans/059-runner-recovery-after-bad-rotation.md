# 059 Runner Recovery After Bad Rotation

## Why this exists

The GitHub runner on `aurelius` was broken by revoking the old PAT before the
new credential was proved by:
- direct API validation
- and a forced service re-registration

That was execution failure. This plan exists to recover the runner with the
smallest possible human step and to prevent the same mistake from happening
again.

## Frozen current state

1. `github-runner-aurelius.service` is currently failed after restart.
2. The current token file on `aurelius` does not support re-registration.
3. The old exposed PAT has already been revoked.
4. The local copy of the PAT on `predator` is already removed.
5. The tracked repo state is still clean:
   - no tracked secrets
   - docs drift passes
   - public-safety passes

## Root cause

The previous execution treated “service still running from an old session” as if
that proved the replacement credential was valid. It did not.

The correct proof order is:
1. validate new credential directly
2. restart runner service
3. verify successful re-registration
4. only then revoke the old credential

## Scope

In scope:
- restore the org runner on `aurelius`
- minimize the human step to one unavoidable credential issuance action
- document the corrected validation order

Out of scope:
- broader Aurelius feature work
- unrelated repo dirt

## Quality bar

1. Do not ask the user to revoke or destroy any working credential until the
   replacement has been proved by restart.
2. Do not ask the user for any action until all machine-side checks that can be
   done without them have been exhausted.
3. The only acceptable final state is:
   - `github-runner-aurelius.service` active
   - journal shows successful registration
   - direct API validation of the current token succeeds

## Execution plan

### Phase 1. Freeze and inspect

1. Reconfirm the exact failure mode from the runner journal.
2. Reconfirm the current token file location and permissions on `aurelius`.
3. Confirm no tracked secret or doc regression occurred while recovering.

### Phase 2. Eliminate guesswork about the credential

1. Validate the current token directly against the GitHub org runner API.
2. If validation fails, treat the token as unusable immediately.
3. Do not restart again or ask for revocation decisions during this phase.

### Phase 3. Prepare the minimal human step

1. Determine the exact credential shape that the runner needs:
   - classic PAT
   - scopes: `admin:org` and `repo`
2. Prepare the exact one-shot host command that writes the token only on
   `aurelius` with the correct permissions.
3. Only then ask the user for the one unavoidable human step:
   - generate a fresh PAT in GitHub UI

### Phase 4. Recover the runner

1. After the user provides the fresh PAT on `aurelius`, validate it directly
   before restart.
2. Restart `github-runner-aurelius.service`.
3. Confirm:
   - `Connected to GitHub`
   - `Successfully replaced the runner` or equivalent successful registration
   - `Listening for Jobs`

### Phase 5. Close the loop

1. Record the corrected validation order in docs/progress.
2. Only after the runner is healthy, tell the user whether any stale runner UI
   entries remain for later cleanup.

## Definition of done

This plan is done only when:

1. `github-runner-aurelius.service` is healthy after a real restart.
2. The current token on `aurelius` is proved valid directly against the GitHub
   org runner API.
3. The user was asked to do only the one unavoidable human step.
4. The corrected validation order is documented so this exact failure is not
   repeated.
