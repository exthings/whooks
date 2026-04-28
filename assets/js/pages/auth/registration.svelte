<script module>
  export { default as layout } from "$layouts/blank.svelte";
</script>

<script lang="ts">
  import { Button } from "$lib/components/ui/button";
  import * as Card from "$lib/components/ui/card";
  import { FieldGroup, Field, FieldLabel } from "$lib/components/ui/field";
  import { Input } from "$lib/components/ui/input";
  import { cn } from "$lib/utils.js";
  import type { HTMLAttributes } from "svelte/elements";
  import WhooksSymbol from "$components/whooks.svelte";
  import { useForm } from "@inertiajs/svelte";

  let { class: className, ...restProps }: HTMLAttributes<HTMLDivElement> =
    $props();

  const form = useForm("auth/register", {
    name: "",
    email: "",
    password: "",
  });

  const handleSubmit = (e: Event) => {
    e.preventDefault();

    $form.post("");
  };
</script>

<svelte:head>
  <title>Whooks - Registration</title>
</svelte:head>

<div
  class="bg-muted flex min-h-svh flex-col items-center justify-center gap-6 p-6 md:p-10"
>
  <div class="flex w-full max-w-sm flex-col gap-6">
    <a href="##" class="flex items-center gap-2 self-center font-medium">
      <div
        class="bg-primary text-primary-foreground flex size-10 p-2 items-center justify-center rounded-md"
      >
        <WhooksSymbol class="fill-white" />
      </div>
      Whooks
    </a>

    <div class={cn("flex flex-col gap-6", className)} {...restProps}>
      <Card.Root>
        <Card.Header class="text-center">
          <Card.Title class="text-xl">Register</Card.Title>
          <Card.Description>Create your account</Card.Description>
        </Card.Header>
        <Card.Content>
          <form onsubmit={handleSubmit}>
            <FieldGroup>
              <Field>
                <FieldLabel for="name">Name</FieldLabel>
                <Input
                  id="name"
                  type="name"
                  placeholder="Your name"
                  bind:value={$form.name}
                  required
                />
              </Field>
              <Field>
                <FieldLabel for="email">Email</FieldLabel>
                <Input
                  id="email"
                  type="email"
                  placeholder="name@example.com"
                  bind:value={$form.email}
                  required
                />
              </Field>
              <Field>
                <FieldLabel for="password">Password</FieldLabel>
                <Input
                  id="password"
                  type="password"
                  bind:value={$form.password}
                  required
                />
              </Field>
              <Field>
                <Button type="submit">Register</Button>
              </Field>
            </FieldGroup>
          </form>
        </Card.Content>
      </Card.Root>
    </div>
  </div>
</div>
