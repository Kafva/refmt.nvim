{#if btnClass != ""}
    <span role="button" class="{'nf '+ btnClass}"
          title="{title}"
          on:click="{() => {
            visible = true;
            visibleButtonsStore.set('');
    }}"/>
{/if}

