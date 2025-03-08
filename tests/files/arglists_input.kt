@Module
@InstallIn(SingletonComponent::class)
object AppContextModule {
    @Provides
    @Singleton
    fun provideDataStore(@ApplicationContext context: Context, param2: String, param3: String, param4: String): DataStore<Preferences>
    {

    }
}

